{% macro safe_cast(column, data_type) %}
    {% if target.type == 'bigquery' %}
        safe_cast({{ column }} as {{ data_type }})
    {% else %}
        cast({{ column }} as {{ data_type }})
    {% endif %}
{% endmacro %}

-- Hvis du ønsker samme “safe” oppførsel i for eksempel PostgreSQL, 
-- må man vanligvis bruke andre teknikker, som:
-- • NULLIF
-- • CASE WHEN
-- • egne valideringsregler i dbt før casting