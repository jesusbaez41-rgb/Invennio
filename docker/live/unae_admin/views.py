"""Admin user-creation views for Repositorio UNAE Análisis.

Provides GET/POST /administration/users/create so the administrator can
create users from the web UI (the users REST API has no create endpoint).
Only presentation is added here; no existing functionality is modified.
"""

from datetime import datetime
from secrets import token_urlsafe

from flask import (
    Blueprint,
    current_app,
    flash,
    redirect,
    render_template,
    request,
    session,
    url_for,
)
from flask_security.forms import ConfirmRegisterForm
from flask_security.utils import hash_password
from invenio_administration.permissions import administration_permission
from werkzeug.datastructures import MultiDict


def _get_datastore():
    """Return the Flask-Security datastore."""
    return current_app.extensions["security"].datastore


def _new_form_token():
    """Issue a one-time form token (double-submit CSRF protection)."""
    token = token_urlsafe(16)
    session["unae_create_token"] = token
    return token


def create_blueprint(app):
    """Create the UNAE admin blueprint."""
    blueprint = Blueprint("unae_admin", __name__)

    @blueprint.route("/administration/users/create", methods=["GET", "POST"])
    @administration_permission.require(http_exception=403)
    def create_user():
        """Render and process the create-user form (admins only)."""
        datastore = _get_datastore()

        if request.method == "POST":
            submitted = (request.form.get("form_token") or "").strip()
            expected = session.pop("unae_create_token", None)
            if not expected or submitted != expected:
                flash("Sesión de formulario inválida. Inténtalo de nuevo.", "error")
                return render_template(
                    "unae_admin/create_user.html",
                    form_token=_new_form_token(),
                    values=request.form,
                    errors={},
                )

            email = (request.form.get("email") or "").strip()
            password = request.form.get("password") or ""
            active = bool(request.form.get("active"))
            confirmed = bool(request.form.get("confirmed"))
            make_admin = bool(request.form.get("make_admin"))

            # Mirror `invenio users create` validation.
            form_data = dict(
                email=email,
                password=password,
                password_confirm=password,
                active="y" if active else "",
            )
            check_form = ConfirmRegisterForm(
                MultiDict(form_data), meta={"csrf": False}
            )
            if not check_form.validate():
                return render_template(
                    "unae_admin/create_user.html",
                    form_token=_new_form_token(),
                    values=request.form,
                    errors=check_form.errors,
                )

            if datastore.find_user(email=email):
                return render_template(
                    "unae_admin/create_user.html",
                    form_token=_new_form_token(),
                    values=request.form,
                    errors={"email": ["Ya existe un usuario con ese correo."]},
                )

            kwargs = dict(email=email, password=hash_password(password))
            kwargs["active"] = active
            if confirmed:
                kwargs["confirmed_at"] = datetime.utcnow()
            user = datastore.create_user(**kwargs)
            if make_admin:
                role = datastore.find_role("admin")
                if role is not None:
                    datastore.add_role_to_user(user, role)
            datastore.commit()

            # Index the new user so it shows up in /administration/users.
            # (Direct indexing: the async reindex task is incompatible with
            # the indexer version in this image.)
            try:
                from invenio_users_resources.proxies import (
                    current_users_service,
                )
                from invenio_users_resources.records.api import UserAggregate

                aggregate = UserAggregate.get_record(str(user.id))
                if aggregate is not None:
                    current_users_service.indexer.index(aggregate)
                    try:
                        current_users_service.indexer.refresh()
                    except Exception:  # noqa: BLE001
                        pass
            except Exception:  # noqa: BLE001 - indexing must not break creation
                current_app.logger.exception(
                    "Could not index new user %s", email
                )

            flash(f"Usuario {email} creado correctamente.", "success")
            return redirect("/administration/users")

        return render_template(
            "unae_admin/create_user.html",
            form_token=_new_form_token(),
            values={},
            errors={},
        )

    return blueprint
