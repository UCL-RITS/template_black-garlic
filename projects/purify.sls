{% set compiler = salt['pillar.get']('compiler', 'gcc') %}
{% set python = salt['pillar.get']('python', 'python3') %}
{% set project = sls.split('.')[-1] %}
{% set workspace = salt['funwith.workspace'](project) %}
{% set pyver = python[:-1] + "@" + python[-1] %}

{% set openmp = "+openmp" if compiler != "clang" else "-openmp" %}
{{project}} spack packages:
  spack.installed:
    - pkgs: &spack_packages
      - openmpi %{{compiler}}
      - fftw %{{compiler}} {{openmp}}
      - gbenchmark %{{compiler}}
      - catch %{{compiler}}
      - spdlog %{{compiler}}
      - wcslib %{{compiler}}
      - cfitsio %{{compiler}}
      - bison %{{compiler}}
{% if compiler != "intel" %}
      - openblas %{{compiler}} {{openmp}}
{% endif %}
      - >
        boost %{{compiler}}
        +python  +singlethreaded
        -mpi -multithreaded -program_options -random -regex -serialization
        -signals -system -test -thread -wave
        ^{{pyver}}
     # - >
     #   casacore %{{compiler}} +python +fftw
     #   ^boost %{{compiler}}
     #    +python  +singlethreaded
     #    -mpi -multithreaded -program_options -random -regex -serialization
     #    -signals -system -test -thread -wave
     #   ^fftw {{openmp}}
     #   ^openblas {{openmp}}


{{project}} virtualenv:
  virtualenv.managed:
     - name: {{workspace}}/{{python}}
     - python: {{python}}
     - use_wheel: True
     - pip_upgrade: True
     - pip_pkgs: [pip, numpy, scipy, pytest, pandas, cython, jupyter]


astro-informatics/purify:
  github.latest:
    - target: {{workspace}}/src/{{project}}
    - unless: test -d {{workspace}}/src/{{project}}/.git


astro-informatics/sopt:
  github.latest:
    - target: {{workspace}}/src/sopt
    - unless: test -d {{workspace}}/src/sopt/.git

  file.directory:
    - name: {{workspace}}/src/sopt/build

  cmd.run:
    - name: |
        cmake -DCMAKE_BUILD_TYPE=RelWithDeInfo \
              -DCMAKE_INSTALL_PREFIX={{workspace}} \
              ..
        make install -j 4
    - creates: {{workspace}}/share/cmake/sopt/SoptConfig.cmake
    - cwd: {{workspace}}/src/sopt/build


{{project}}:
  funwith.modulefile:
    - prefix: {{workspace}}
    - cwd: {{workspace}}/src/{{project}}
    - spack: *spack_packages
    - virtualenv: {{workspace}}/{{python}}
    - footer: |
{% if compiler == "gcc" %}
        setenv("CXXFLAGS", "-Wno-parentheses -Wno-deprecated-declarations")
{% endif %}
{% if compiler != "intel" %}
        setenv("BLA_VENDOR", "OpenBLAS")
{% endif %}


{{workspace}}/data/:
  file.directory


{{workspace}}/data/WSRT_Measures:
  archive.extracted:
    - source: ftp://ftp.astron.nl/outgoing/Measures/WSRT_Measures.ztar
    - source_hash: md5=69d0e8aa479585f1be65be2ca51a9e25
    - archive_format: tar
    - tar_options: z
    - if_missing: {{workspace}}/data/WSRT_Measures/ephemerides
