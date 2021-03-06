{% set compiler = salt["spack.compiler"]() %}
{% set python = salt['spack.python']() %}
{% set project = sls.split('.')[-1] %}
{% set workspace = salt['funwith.workspace'](project) %}

{{project}} spack packages:
  spack.installed:
    - pkgs: &spack_packages
      - GreatCMakeCookoff
      - boost %{{compiler}}
      - openmpi %{{compiler}}
      - hdf5 %{{compiler}} -fortran -cxx +mpi ^openmpi
      - metis %{{compiler}} +real64
      - parmetis %{{compiler}} ^openmpi ^metis +real64
      - Tinyxml %{{compiler}}
      - cppunit %{{compiler}}
      - CTemplate %{{compiler}}


UCL-CCS/hemelb-dev:
  github.latest:
    - target: {{workspace}}/src/{{project}}
    - unless: test -d {{workspace}}/src/{{project}}/.git

{{workspace}}/src/hemelb/build/tmp:
      file.directory:
        - makedirs: True


{{workspace}}/{{python}}:
  virtualenv.managed:
    - python: {{salt['spack.python_exec']()}}
    - pip_upgrade: True
    - use_wheel: True
    - pip_pkgs: [pip, numpy, scipy, pandas, jupyter]


{{project}}:
  funwith.modulefile:
    - spack: *spack_packages
    - cwd: {{workspace}}/src/{{project}}
    - virtualenv: {{workspace}}/{{python}}
