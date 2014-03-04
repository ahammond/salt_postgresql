{% set pg_collectd = '/etc/collectd.d/postgresql.conf' %}
{{ pg_collectd }}:
  file.managed:
    - source: salt://postgresql/files{{ pg_collectd }}
    - template: jinja
    - databases: {{ pillar['postgresql']['databases'] }}

{% set contextswitch = '/etc/collectd.d/contextswitch.conf' %}
{{ contextswitch }}:
  file.managed:
    - source: salt://postgresql/files{{ contextswitch }}
    - template: jinja

{% set tcpconns = '/etc/collectd.d/tcpconns.conf' %}
{{ tcpconns }}:
  file.managed:
    - source: salt://postgresql/files{{ tcpconns }}
    - template: jinja