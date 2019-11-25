import os
import sys
from glob import glob
import shutil
import subprocess
import git

repo = git.Repo(search_parent_directories=True)
is_travis = os.environ.get('TRAVIS')
if is_travis:
    if os.environ.get('TRAVIS_EVENT_TYPE') == 'pull_request':
        branch_name = os.environ.get('TRAVIS_PULL_REQUEST_BRANCH')
    else:
        branch_name = os.environ.get('TRAVIS_BRANCH')
else:
    branch_name = repo.active_branch.name


def pytest_generate_tests(metafunc):
    if 'app' in metafunc.fixturenames:
        apps = []

        for app_dir in glob(os.path.join('tools', '*')) \
            + glob(os.path.join('workflows', '*')):
            app_dir_cwl = app_dir
            app_dir_nf = app_dir
            if app_dir.startswith('workflows'):
                app_dir_cwl = os.path.join(app_dir, 'cwl')
                app_dir_nf = os.path.join(app_dir, 'nextflow')

            app_name = os.path.basename(app_dir)
            if branch_name not in ('master', 'develop') and not branch_name.startswith('%s.' % app_name):
                continue  # don't need to test

            app_def_cwl = glob(os.path.join(app_dir_cwl, '*.cwl'))
            app_def_nf = glob(os.path.join(app_dir_nf, '*.nf'))

            assert len(app_def_cwl) <= 1, \
                'A app dir can not have more than one ".cwl" file in %s' % app_dir_cwl
            assert len(app_def_nf) <= 1, \
                'A app dir can not have more than one ".nf" file in %s' % app_dir_nf

            if not app_def_cwl and not app_def_nf:
                continue

            for test_job in glob(os.path.join(app_dir_cwl, 'tests', '*.yaml')) + \
                            glob(os.path.join(app_dir_nf, 'tests', '*.nf.json')):
                test_dir = os.path.dirname(test_job)
                test_file_name = os.path.basename(test_job)
                if is_travis and test_file_name.startswith('local-'):
                    continue

                apps.append([
                    os.path.basename(app_def_cwl[0] if test_job.endswith('.yaml') else app_def_nf[0]),
                    test_dir,
                    test_job
                ])

        metafunc.parametrize('app', apps, ids=[v[2] for v in apps])


def test_app(app, rootDir):
    app_file_name, test_dir, test_job = app
    app_dir = test_dir.split(os.sep)[1]

    assert app_file_name == app_dir + '.cwl' or app_file_name == app_dir + '.nf', \
        'APP file must be named as <containing_dir_name>.cwl, dir_name: %s, app_file_name: %s' % \
            (app_dir, app_file_name)

    app_file = os.path.join('..', app_file_name)
    test_job_file = os.path.basename(test_job)

    os.chdir(os.path.join(rootDir, test_dir))

    app_outdir = 'outdir'
    if os.path.exists(app_outdir):  # remove if exist
        shutil.rmtree(app_outdir)

    os.makedirs(app_outdir)

    if app_file_name.endswith('.cwl'):
        cmd = "cwltool --non-strict --no-read-only --outdir %s %s %s" % \
            (app_outdir, app_file, test_job_file)  # we can implement checker.cwl as well to perform result comparison
    elif app_file_name.endswith('.nf'):
        cmd = "nextflow run -w %s -params-file %s %s" % \
            (app_outdir, test_job_file, 'checker.nf')
    else:
        assert False, 'Unknown app type for %s. Only .cwl and .nf are supported' % app_file_name

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
