from sqlalchemy.orm import Session
from ..models.audit_log import AuditLog
from datetime import datetime

def log_audit_action(db: Session, user_id: str, user_role: str, action: str, details: str = None):
    log = AuditLog(
        user_id=user_id,
        user_role=user_role,
        action=action,
        details=details,
        created_at=datetime.utcnow()
    )
    db.add(log)
    db.commit()
