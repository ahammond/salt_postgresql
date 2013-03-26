{% set pg_pref = '/etc/apt/preferences.d/pgdg.pref' %}
{% set ppa = 'deb http://ppa.launchpad.net/pitti/postgresql/ubuntu precise main' %}

{{ ppa }}
  pkgrepo.managed:
    - dist: precise
    - file: /etc/apt/sources.list.d/postgresql.list
    - keyid: FB322597BBC86D52FEE950E299B656EA8683D8A2
    - keyserver: keyserver.ubuntu.com

{{ pg_pref }}:
  file.managed:
    - source: salt://postgresql/files{{ pg_pref }}
    - require:
      - pkgrepo: {{ ppa }}

update_apt:
  cmd.wait:
    - name: apt-get update
    - require:
      - pkgrepo: {{ ppa }}
      - file: {{ pg_perf }}
    - watch:
      - file: /etc/apt/sources.list.d/*
