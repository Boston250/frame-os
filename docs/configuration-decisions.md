# Production configuration decisions

| Decision | Value | Status |
|---|---|---|
| Legal operating country | Rwanda | Confirmed |
| Country code | RW | Derived from confirmed country |
| Primary timezone | Africa/Kigali | Derived; pending only if FRAME requests another timezone |
| Base currency | RWF — Rwandan franc | Derived; pending only if FRAME requests another accounting currency |
| Launch data strategy | Start empty; staff enter records directly | Confirmed |
| Legacy import tools | Not required for launch | Derived from confirmed strategy |
| Employee account creators | Super Admin and HR | Confirmed |
| Employee creation approval | Not required; permission and audit controlled | Derived from confirmed choice |
| New employee password | System-generated temporary password | Confirmed |
| First login | Password change required | Confirmed |
| Two-factor authentication | Disabled | Confirmed |
| Inactivity logout | 60 minutes | Confirmed |
| Forgotten-password reset | HR or Super Admin issues temporary password | Confirmed |
| Self-service password reset | Disabled | Derived from confirmed choice |
| Interface language | English only | Confirmed |
| Tax/VAT features | Disabled | Confirmed |
| Finance scope | Internal accounting and operational finance | Confirmed |
| Attendance location | One approved office network | Confirmed |
| Office Wi-Fi label | FRAME MEDIA AGENCY | Confirmed |
| Attendance network address | Pending production network discovery | Required technical value, not a business decision |
