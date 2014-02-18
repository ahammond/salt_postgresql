{% from 'postgresql/map.jinja' import postgresql with context %}
# Install and configure pgbadger to run in incremental mode

{% set pgbadger_tarball = "/usr/src/pgbadger-v5.0.tar.gz" %}
{% set pgbadger_url = "https://codeload.github.com/dalibo/pgbadger/tar.gz/v5.0" %}
{{ pgbadger_tarball }}:
  file.managed:
    - source: {{ pgbadger_url }}
    - source_hash: md5=c33fcaf70728037e64225616d557340d
    - owner: nobody

{% set pgbadger_src_dir = "/usr/src/pgbadger-5.0" %}
{{ pgbadger_src_dir }}:
  file.directory:
    - user: nobody
    - dirmode: 755

{% set untar_pgbadger = "tar xzf %s" % pgbadger_tarball %}
{{ untar_pgbadger }}:
  cmd.run:
    - cwd: /usr/src
    - user: nobody
    - unless: test -e {{ pgbadger_src_dir }}/README
    - require:
      - file: {{ pgbadger_tarball }}
      - file: {{ pgbadger_src_dir }}

pgbadger_requirements:
  pkg.installed:
    - pkgs:
      - perl-ExtUtils-MakeMaker

{% set perl_makefile = "perl Makefile.PL" %}
{{ perl_makefile }}:
  cmd.run:
    - cwd: {{ pgbadger_src_dir }}
    - user: nobody
    - unless: test -e {{ pgbadger_src_dir }}/Makefile
    - require:
      - cmd: {{ untar_pgbadger }}
      - pkg: pgbadger_requirements

make:
  cmd.run:
    - cwd: {{ pgbadger_src_dir }}
    - user: nobody
    - unless: test -d {{ pgbadger_src_dir }}/blib
    - require:
      - cmd: {{ perl_makefile }}

{% set pgbadger_bin = "/usr/local/bin/pgbadger" %}
make install:
  cmd.run:
    - cwd: {{ pgbadger_src_dir }}
    - unless: test -x {{ pgbadger_bin }}
    - require:
      - cmd: make

{{ postgresql.pgbadger_outdir }}:
  file.directory:
    - user: postgres
    - group: postgres
    - mode: 755

{% set pgbadger_cron = "%s --quiet --incremental --jobs 8 --outdir %s --last-parsed %s/pgbadger_incremental_file.data `/bin/find %s -name '*.log' 2> /dev/null`" % (pgbadger_bin, postgresql.pgbadger_outdir, postgresql.log_dir, postgresql.log_dir) %}
{{ pgbadger_cron }}:
  cron.present:
    - user: postgres
    - minute: random
    - hour: '*/2'
#}
