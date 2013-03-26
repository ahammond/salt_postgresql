{% for user in pillar['postgresql']['users'] %}
{{ user }}:
  postgres_user.present:
    runas: postgres
    {% for k, v in user.items() %}
    - {{ k }}: {{ v }}
    {% endfor %}
{% endfor %}
