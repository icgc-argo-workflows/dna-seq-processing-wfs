import os
import sys
from glob import glob
import shutil
import subprocess

is_travis = os.environ.get('TRAVIS')


def pytest_generate_tests(metafunc):
    if 'job' in metafunc.fixturenames:
        jobs = []
        for test_dir in glob(os.path.join('*', 'tests')):
            for test_job in glob(os.path.join(test_dir, '*.json')):
                if is_travis and os.path.basename(test_job).startswith('local-'): continue

                jobs.append([
                                "%s/%s" % (test_dir, os.path.basename(test_job)),
                                os.path.abspath(test_dir),
                                os.path.abspath(test_job)
                            ])

        metafunc.parametrize('job', jobs, ids=[j[0] for j in jobs])


def test_app(job, rootDir):
    _, test_dir, test_job = job

    os.chdir(test_dir)

    app_outdir = 'outdir'
    if os.path.exists(app_outdir):  # remove if exist
        shutil.rmtree(app_outdir)

    os.makedirs(app_outdir)

    cmd = "nextflow run -w %s -params-file %s %s" % \
        (app_outdir, test_job, 'checker.nf')

    p = subprocess.Popen(
                            [cmd],
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE,
                            shell=True
                        )

    stdout, stderr = p.communicate()

    if p.returncode != 0:  # test run failed
        print(stdout)
        print(stderr, file=sys.stderr)
        assert False, 'Failed with return code: %s; CMD: %s' % (p.returncode, cmd)
    else:
        if os.path.exists(app_outdir):  # clean up
            shutil.rmtree(app_outdir)
        assert True
