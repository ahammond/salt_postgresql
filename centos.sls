{% from 'postgresql/map.jinja' import postgresql with context %}

patch:
  pkg.installed

{# CentOS includes a very old version of PostgreSQL. Exclude it. #}
{% set centos_base_repo = '/etc/yum.repos.d/CentOS-Base.repo' %}
{{ centos_base_repo }}:
  file.patch:
    - source: salt://postgresql/files{{ centos_base_repo }}.patch
    - hash: md5=2b27e3f9c4878d92f8ee5393be69f8d0
    - require:
      - pkg: patch

{% set pgdg_gpg_key = '/etc/pki/rpm-gpg/RPM-GPG-KEY-PGDG-92' %}
{{ pgdg_gpg_key }}:
  file.managed:
    - source: salt://postgresql/files{{ pgdg_gpg_key }}

{% set pgdg_repo = 'pgdg-92-centos' %}
{{ pgdg_repo }}:
  pkgrepo.managed:
    - humanname: PostgreSQL 9.2 $releasever - $basearch
    - baseurl: http://yum.postgresql.org/9.2/redhat/rhel-$releasever-$basearch
    - gpgcheck: 1
    - gpgkey: file://{{ pgdg_gpg_key }}
    - require:
      - file: {{ pgdg_gpg_key }}

{{ postgresql.pkg }}:
  pkg.installed:
    - require:
      - pkgrepo: {{ pgdg_repo }}
      - file: {{ centos_base_repo }}

{% if postgresql.initdb %}
# CentOS requires us to manually run initdb, which is probably a good idea, but... mildly annoying.
service postgresql-9.2 initdb:
  cmd.run:
    - unless: test -d {{ postgresql.pgdata }}/base
    - require:
      - pkg: {{ postgresql.pkg }}
{% endif %}
