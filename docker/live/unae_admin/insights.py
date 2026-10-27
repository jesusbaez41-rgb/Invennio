"""Estadísticas de usuarios para el panel de administración.

Calcula, a partir de la base de datos, datos de interés sobre las personas
que usan el repositorio (altas, accesos y depósitos publicados). Se usa
únicamente para pintar el panel de /administration/users.
"""

import time
from datetime import datetime

from invenio_db import db
from sqlalchemy import text

_CACHE = {"at": 0, "data": None}
_TTL = 60  # segundos


def _rows(sql, **params):
    return db.session.execute(text(sql), params).mappings().all()


def _initials(name, email):
    name = (name or "").strip()
    if name:
        parts = [p for p in name.split() if p]
        if len(parts) >= 2:
            return (parts[0][0] + parts[1][0]).upper()
        return parts[0][:2].upper()
    return (email or "?")[:2].upper()


def _hue(email):
    return sum(ord(c) for c in (email or "x")) % 360


def collect():
    """Return a dict with the user-management insights."""
    now = time.time()
    if _CACHE["data"] is not None and now - _CACHE["at"] < _TTL:
        return _CACHE["data"]

    users = _rows(
        """
        SELECT u.id, u.email, u.username, u.active, u.confirmed_at, u.created,
               COALESCE(u.profile->>'full_name', u.profile->>'name', '') AS full_name,
               u.profile->>'affiliation' AS affiliation,
               li.last_login_at, COALESCE(li.login_count, 0) AS login_count,
               EXISTS (
                   SELECT 1 FROM accounts_userrole ur
                   JOIN accounts_role r ON r.id = ur.role_id
                   WHERE ur.user_id = u.id AND r.name = 'admin'
               ) AS is_admin
        FROM accounts_user u
        LEFT JOIN accounts_user_login_information li ON li.user_id = u.id
        ORDER BY u.created DESC
        """
    )

    deposits = {}
    try:
        for row in _rows(
            """
            SELECT owner_id, count(*) AS total, max(created) AS last_at
            FROM (
                SELECT (jsonb_array_elements_text(
                           json->'parent'->'access'->'owned_by'))::int AS owner_id,
                       created
                FROM rdm_records_metadata
                WHERE jsonb_typeof(json->'parent'->'access'->'owned_by') = 'array'
                  AND COALESCE(deletion_status, '') <> 'P'
                UNION ALL
                SELECT (json->'parent'->'access'->>'owned_by')::int AS owner_id,
                       created
                FROM rdm_records_metadata
                WHERE jsonb_typeof(json->'parent'->'access'->'owned_by') = 'string'
                  AND COALESCE(deletion_status, '') <> 'P'
            ) owners
            GROUP BY owner_id
            """
        ):
            deposits[row["owner_id"]] = {
                "total": int(row["total"]),
                "last_at": row["last_at"],
            }
    except Exception:  # noqa: BLE001 - el panel nunca debe romperse
        db.session.rollback()

    people = []
    for u in users:
        dep = deposits.get(u["id"], {})
        people.append(
            {
                "id": u["id"],
                "email": u["email"],
                "name": u["full_name"] or u["username"] or u["email"],
                "initials": _initials(u["full_name"] or u["username"], u["email"]),
                "hue": _hue(u["email"]),
                "active": bool(u["active"]),
                "confirmed": u["confirmed_at"] is not None,
                "is_admin": bool(u["is_admin"]),
                "created": u["created"],
                "last_login_at": u["last_login_at"],
                "login_count": int(u["login_count"] or 0),
                "deposits": dep.get("total", 0),
                "last_deposit_at": dep.get("last_at"),
            }
        )

    total_deposits = sum(p["deposits"] for p in people)
    contributors = sorted(
        [p for p in people if p["deposits"]], key=lambda p: p["deposits"], reverse=True
    )

    data = {
        "people": people,
        "total_users": len(people),
        "active_users": sum(1 for p in people if p["active"]),
        "confirmed_users": sum(1 for p in people if p["confirmed"]),
        "admins": sum(1 for p in people if p["is_admin"]),
        "total_deposits": total_deposits,
        "contributors": contributors[:6],
        "recent_users": people[:5],
        "recent_logins": sorted(
            [p for p in people if p["last_login_at"]],
            key=lambda p: p["last_login_at"],
            reverse=True,
        )[:5],
        "with_deposits": len(contributors),
        "generated_at": datetime.utcnow(),
    }
    _CACHE["data"] = data
    _CACHE["at"] = now
    return data
