from pathlib import Path
import csv
import math

import matplotlib.pyplot as plt


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "experiment-results" / "economic-model"
OUT.mkdir(parents=True, exist_ok=True)

# Measured values from the last full experiment.
MANUAL_5_SERVICES_1_ENV = 531
META_5_SERVICES_3_ENVS = 376
META_BILLING_SERVICE_LINES = 13

# Derived constants.
MANUAL_LINES_PER_SERVICE_PER_ENV = MANUAL_5_SERVICES_1_ENV / 5  # 106.2
META_SERVICE_LINES = 13
META_ENV_LINES = 24

# Fixed part is calculated so that Lmeta(5, 3) = 376.
META_FIXED = META_5_SERVICES_3_ENVS - META_SERVICE_LINES * 5 - META_ENV_LINES * 3

# Economic assumptions.
LINES_PER_HOUR = 120
INITIAL_DESIGN_HOURS = 4


def manual_lines(services: int, environments: int) -> float:
    return MANUAL_LINES_PER_SERVICE_PER_ENV * services * environments


def meta_lines(services: int, environments: int) -> float:
    return META_FIXED + META_SERVICE_LINES * services + META_ENV_LINES * environments


def manual_hours(services: int, environments: int) -> float:
    return manual_lines(services, environments) / LINES_PER_HOUR


def meta_hours(services: int, environments: int) -> float:
    return INITIAL_DESIGN_HOURS + meta_lines(services, environments) / LINES_PER_HOUR


def reduction_percent(manual: float, meta: float) -> float:
    if manual == 0:
        return 0
    return (manual - meta) / manual * 100


# 1. Break-even by number of services for 3 environments.
service_rows = []
for n in range(1, 11):
    m_lines = manual_lines(n, 3)
    h_lines = meta_lines(n, 3)
    m_hours = manual_hours(n, 3)
    h_hours = meta_hours(n, 3)

    service_rows.append({
        "services": n,
        "manual_lines": round(m_lines, 1),
        "metachart_lines": round(h_lines, 1),
        "saved_lines": round(m_lines - h_lines, 1),
        "saved_percent": round(reduction_percent(m_lines, h_lines), 1),
        "manual_hours": round(m_hours, 2),
        "metachart_hours_with_initial_design": round(h_hours, 2),
        "saved_hours_with_initial_design": round(m_hours - h_hours, 2),
    })

with open(OUT / "break-even-by-services.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=service_rows[0].keys())
    writer.writeheader()
    writer.writerows(service_rows)

# Chart 1: economic break-even in hours.
x = [row["services"] for row in service_rows]
manual_h = [row["manual_hours"] for row in service_rows]
meta_h = [row["metachart_hours_with_initial_design"] for row in service_rows]
saved_h = [row["saved_hours_with_initial_design"] for row in service_rows]

plt.figure(figsize=(9, 5))
plt.plot(x, manual_h, marker="o", label="Manual YAML")
plt.plot(x, meta_h, marker="o", label="Helm metachart")
plt.axhline(0, linewidth=1)
plt.xlabel("Number of services")
plt.ylabel("Estimated configuration effort, hours")
plt.title("Break-even point by number of services, 3 environments")
plt.legend()
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig(OUT / "break-even-services-hours.png", dpi=200)
plt.close()

plt.figure(figsize=(9, 5))
plt.plot(x, saved_h, marker="o", label="Net saved hours")
plt.axhline(0, linewidth=1)
plt.xlabel("Number of services")
plt.ylabel("Net saving, hours")
plt.title("Net saving after initial metachart design cost")
plt.legend()
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig(OUT / "net-saving-services.png", dpi=200)
plt.close()

# 2. Lines per service bar chart.
manual_per_service = manual_lines(5, 3) / 5
meta_per_service = meta_lines(5, 3) / 5

per_service_rows = [
    {"approach": "Manual YAML", "lines_per_service": round(manual_per_service, 1)},
    {"approach": "Helm metachart", "lines_per_service": round(meta_per_service, 1)},
]

with open(OUT / "lines-per-service.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=per_service_rows[0].keys())
    writer.writeheader()
    writer.writerows(per_service_rows)

plt.figure(figsize=(7, 5))
plt.bar(
    [row["approach"] for row in per_service_rows],
    [row["lines_per_service"] for row in per_service_rows],
)
plt.ylabel("Lines per service")
plt.title("Configuration lines per service, 5 services and 3 environments")
plt.tight_layout()
plt.savefig(OUT / "lines-per-service.png", dpi=200)
plt.close()

# 3. Growth by number of environments for 5 services.
env_rows = []
for e in range(1, 6):
    m = manual_lines(5, e)
    h = meta_lines(5, e)

    env_rows.append({
        "environments": e,
        "manual_lines": round(m, 1),
        "metachart_lines": round(h, 1),
        "saved_lines": round(m - h, 1),
        "saved_percent": round(reduction_percent(m, h), 1),
    })

with open(OUT / "growth-by-environments.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=env_rows[0].keys())
    writer.writeheader()
    writer.writerows(env_rows)

x_env = [row["environments"] for row in env_rows]
manual_env = [row["manual_lines"] for row in env_rows]
meta_env = [row["metachart_lines"] for row in env_rows]

plt.figure(figsize=(9, 5))
plt.plot(x_env, manual_env, marker="o", label="Manual YAML")
plt.plot(x_env, meta_env, marker="o", label="Helm metachart")
plt.xlabel("Number of environments")
plt.ylabel("Configuration lines")
plt.title("Configuration growth by number of environments, 5 services")
plt.legend()
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig(OUT / "growth-by-environments.png", dpi=200)
plt.close()

# 4. Summary.
summary = f"""# Economic model summary

## Assumptions

- Manual lines per service per environment: {MANUAL_LINES_PER_SERVICE_PER_ENV:.1f}
- Metachart fixed part: {META_FIXED}
- Metachart marginal service block: {META_SERVICE_LINES}
- Average environment override: {META_ENV_LINES}
- Estimated configuration processing rate: {LINES_PER_HOUR} lines/hour
- Initial metachart design cost: {INITIAL_DESIGN_HOURS} hours

## Main conclusions

- Technical line-count break-even for 3 environments starts from 2 services.
- Economic break-even with initial design cost of {INITIAL_DESIGN_HOURS} hours starts from about 3 services.
- For 5 services and 3 environments:
  - manual baseline: {manual_lines(5, 3):.0f} lines;
  - metachart: {meta_lines(5, 3):.0f} lines;
  - reduction: {reduction_percent(manual_lines(5, 3), meta_lines(5, 3)):.1f}%;
  - manual estimated effort: {manual_hours(5, 3):.2f} hours;
  - metachart estimated effort including initial design: {meta_hours(5, 3):.2f} hours;
  - net saving: {manual_hours(5, 3) - meta_hours(5, 3):.2f} hours.

## Generated files

- break-even-by-services.csv
- break-even-services-hours.png
- net-saving-services.png
- lines-per-service.csv
- lines-per-service.png
- growth-by-environments.csv
- growth-by-environments.png
"""

(OUT / "economic-summary.md").write_text(summary, encoding="utf-8")

print(f"Done. Results saved to: {OUT}")