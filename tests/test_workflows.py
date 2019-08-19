import os
import sys
from glob import glob
import shutil
import subprocess

is_travis = os.environ.get('TRAVIS')

def pytest_generate_tests(metafunc):
    if 'app' in metafunc.fixturenames:
        apps = []

        for app_dir in glob(os.path.join('tools', '*')) \
            + glob(os.path.join('workflows', '*')):
            if app_dir.startswith('workflows'):
                app_dir = os.path.join(app_dir, 'cwl')

            app_def = glob(os.path.join(app_dir, '*.cwl'))

            assert len(app_def) <= 1, \
                'A app dir can not have more than one ".cwl" file in %s' % app_dir

            if not app_def:
                continue

            for test_job in glob(os.path.join(app_dir, 'tests', '*.yaml')):
                test_dir = os.path.dirname(test_job)
                test_file_name = os.path.basename(test_job)
                if is_travis and test_file_name.startswith('local-'):
                    continue

                apps.append([
                    os.path.basename(app_def[0]),
                    test_dir,
                    test_job
                ])

        metafunc.parametrize('app', apps, ids=[v[2] for v in apps])


def test_app(app, rootDir):
    cwl_file_name, test_dir, test_job = app
    app_dir = test_dir.split(os.sep)[1]

    assert cwl_file_name == app_dir + '.cwl', \
        'CWL file must be named as <containing_dir_name>.cwl, dir_name: %s, cwl_file_name: %s' % \
            (app_dir, cwl_file_name)

    cwl_file = os.path.join('..', cwl_file_name)
    test_job_file = os.path.basename(test_job)

    os.chdir(os.path.join(rootDir, test_dir))

    cwl_outdir = 'outdir'
    if os.path.exists(cwl_outdir):  # remove if exist
        shutil.rmtree(cwl_outdir)

    os.makedirs(cwl_outdir)

    cmd = "cwltool --non-strict --no-read-only --outdir %s %s %s" % \
        (cwl_outdir, cwl_file, test_job_file)

    p = subprocess.Popen(
                            [cmd],
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE,
                            shell=True
                        )

    stdout, stderr = p.communicate()

    if p.returncode != 0:  # cwltool run failed
        print(stdout)
        print(stderr, file=sys.stderr)
        assert False, 'Failed with return code: %s; CMD: %s' % (p.returncode, cmd)
    else:
        if os.path.exists(cwl_outdir):  # clean up
            shutil.rmtree(cwl_outdir)
        assert True
