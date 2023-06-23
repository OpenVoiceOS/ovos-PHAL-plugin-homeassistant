#!/usr/bin/env python3
import os
from setuptools import setup

BASEDIR = os.path.abspath(os.path.dirname(__file__))


def get_version():
    """ Find the version of the package"""
    version = None
    version_file = os.path.join(BASEDIR, 'ovos_PHAL_plugin_homeassistant', 'version.py')
    major, minor, build, alpha = (None, None, None, None)
    with open(version_file) as f:
        for line in f:
            if 'VERSION_MAJOR' in line:
                major = line.split('=')[1].strip()
            elif 'VERSION_MINOR' in line:
                minor = line.split('=')[1].strip()
            elif 'VERSION_BUILD' in line:
                build = line.split('=')[1].strip()
            elif 'VERSION_ALPHA' in line:
                alpha = line.split('=')[1].strip()

            if ((major and minor and build and alpha) or
                    '# END_VERSION_BLOCK' in line):
                break
    version = f"{major}.{minor}.{build}"
    if alpha and int(alpha) > 0:
        version += f"a{alpha}"
    return version


def required(requirements_file):
    """ Read requirements file and remove comments and empty lines. """
    with open(os.path.join(BASEDIR, requirements_file), 'r') as f:
        requirements = f.read().splitlines()
        if 'MYCROFT_LOOSE_REQUIREMENTS' in os.environ:
            print('USING LOOSE REQUIREMENTS!')
            requirements = [r.replace('==', '>=').replace('~=', '>=') for r in requirements]
        return [pkg for pkg in requirements
                if pkg.strip() and not pkg.startswith("#")]


def package_files(directory):
    paths = []
    for (path, directories, filenames) in os.walk(directory):
        for filename in filenames:
            paths.append(os.path.join('..', path, filename))
    return paths


def get_description():
    with open(os.path.join(BASEDIR, "README.md"), "r") as f:
        long_description = f.read()
    return long_description

PLUGIN_ENTRY_POINT = 'ovos-PHAL-plugin-homeassistant=ovos_PHAL_plugin_homeassistant:HomeAssistantPlugin'
setup(
    name='ovos-PHAL-plugin-homeassistant',
    version=get_version(),
    description='Homeassistant PHAL plugin for OpenVoiceOS',
    long_description=get_description(),
    long_description_content_type="text/markdown",
    url='https://github.com/OpenVoiceOS/ovos-PHAL-plugin-homeassistant',
    author='Aiix',
    author_email='aix.m@outlook.com',
    license='Apache-2.0',
    packages=['ovos_PHAL_plugin_homeassistant'],
    package_data={'': package_files('ovos_PHAL_plugin_homeassistant')},
    install_requires=required("requirements.txt"),
    zip_safe=True,
    include_package_data=True,
    data_files=[
        ('share/applications', ['res/desktop/ovos-phal-homeassistant.desktop']),
        ('share/icons', ['res/icon/ovos-phal-homeassistant.svg'])
    ],
    classifiers=[
        'Development Status :: 3 - Alpha',
        'Intended Audience :: Developers',
        'Topic :: Utilities',
        'License :: OSI Approved :: Apache Software License',
        'Programming Language :: Python :: 3.5',
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
    ],
    entry_points={'ovos.plugin.phal': PLUGIN_ENTRY_POINT}
)
