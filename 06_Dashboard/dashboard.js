// ============================================================
// Healthcare Analytics Operations Console
// All figures are computed from the embedded dataset (see <script id="dashboard-data">)
// ============================================================
const DATA = JSON.parse(document.getElementById('dashboard-data').textContent);

// ---------- helpers ----------
const fmtINR = (n) => {
  if (n === null || n === undefined) return '—';
  n = Number(n);
  return '₹' + n.toLocaleString('en-IN', { maximumFractionDigits: 0 });
};
const fmtNum = (n) => Number(n).toLocaleString('en-IN');
const fmtPct = (n) => (n === null || n === undefined) ? '—' : `${n > 0 ? '+' : ''}${n}%`;
const fmtDate = (d) => {
  if (!d) return '—';
  const dt = new Date(d);
  return dt.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });
};

// palette
const C = {
  mint: '#35E0C2', mintDim: 'rgba(53,224,194,0.18)',
  coral: '#FF6B6B', coralDim: 'rgba(255,107,107,0.18)',
  gold: '#F5B942', goldDim: 'rgba(245,185,66,0.18)',
  violet: '#8C7CFF', violetDim: 'rgba(140,124,255,0.18)',
  blue: '#5AA9E6', blueDim: 'rgba(90,169,230,0.18)',
  text: '#EAF0FB', muted: '#8291B5', grid: 'rgba(33,45,76,0.6)'
};
const PALETTE = [C.mint, C.violet, C.gold, C.coral, C.blue, '#E084D8', '#7FE0A0', '#F58B6B'];

Chart.defaults.font.family = "'IBM Plex Sans', sans-serif";
Chart.defaults.font.size = 11.5;
Chart.defaults.color = C.muted;

const baseGrid = { color: C.grid, drawTicks: false };
const baseTicks = { color: C.muted };

// ============================================================
// TIMESTAMP + STATUS
// ============================================================
document.getElementById('timestamp').textContent =
  `Snapshot generated ${new Date(DATA.meta.generated_at).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' })}`;
document.getElementById('footerNote').textContent = DATA.meta.note;

// ============================================================
// KPI STRIP
// ============================================================
const kpi = DATA.kpi;
const kpiDefs = [
  { label: 'Total Revenue (Paid)', value: fmtINR(kpi.total_revenue), sub: `Avg bill ${fmtINR(kpi.avg_bill_value)}`, accent: C.mint },
  { label: 'Pending Receivables', value: fmtINR(kpi.pending_receivables), sub: 'Unsettled net amount', accent: C.gold },
  { label: 'Total Patients', value: fmtNum(kpi.total_patients), sub: `${fmtNum(kpi.active_inpatients)} currently admitted`, accent: C.violet },
  { label: 'Doctors on Staff', value: fmtNum(kpi.total_doctors), sub: `${fmtNum(kpi.active_doctors)} active`, accent: C.blue },
  { label: 'Appointments', value: fmtNum(kpi.total_appointments), sub: `${fmtNum(kpi.completed_appointments)} completed`, accent: C.mint },
  { label: 'Departments', value: fmtNum(kpi.total_departments), sub: `${fmtNum(kpi.active_medications)} active prescriptions`, accent: C.coral },
];
document.getElementById('kpiStrip').innerHTML = kpiDefs.map(k => `
  <div class="kpi-card" style="--kpi-accent:${k.accent}">
    <div class="kpi-label">${k.label}</div>
    <div class="kpi-value">${k.value}</div>
    <div class="kpi-sub">${k.sub}</div>
  </div>
`).join('');

// ============================================================
// TABS
// ============================================================
document.querySelectorAll('.tab-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
    btn.classList.add('active');
    document.getElementById('tab-' + btn.dataset.tab).classList.add('active');
  });
});

// ============================================================
// OVERVIEW TAB
// ============================================================
(function () {
  const trend = DATA.monthly_revenue_trend;
  new Chart(document.getElementById('chartRevenueTrend'), {
    type: 'bar',
    data: {
      labels: trend.map(r => r.billing_month),
      datasets: [
        { type: 'line', label: 'Cumulative Revenue', data: trend.map(r => r.cumulative_revenue), borderColor: C.violet, backgroundColor: 'transparent', yAxisID: 'y1', tension: 0.35, pointRadius: 0, borderWidth: 2 },
        { type: 'bar', label: 'Monthly Revenue', data: trend.map(r => r.monthly_revenue), backgroundColor: C.mintDim, borderColor: C.mint, borderWidth: 1, borderRadius: 3, yAxisID: 'y' },
      ]
    },
    options: {
      responsive: true, maintainAspectRatio: false,
      interaction: { mode: 'index', intersect: false },
      plugins: { legend: { position: 'top', labels: { boxWidth: 10, usePointStyle: true } }, tooltip: { callbacks: { label: (ctx) => `${ctx.dataset.label}: ${fmtINR(ctx.parsed.y)}` } } },
      scales: {
        x: { grid: { display: false }, ticks: { ...baseTicks, maxRotation: 0, autoSkip: true, maxTicksLimit: 8 } },
        y: { position: 'left', grid: baseGrid, ticks: { ...baseTicks, callback: v => '₹' + (v / 1000) + 'k' } },
        y1: { position: 'right', grid: { display: false }, ticks: { ...baseTicks, callback: v => '₹' + (v / 1000) + 'k' } },
      }
    }
  });

  const statusData = DATA.appointment_status;
  new Chart(document.getElementById('chartApptStatus'), {
    type: 'doughnut',
    data: {
      labels: statusData.map(r => r.status),
      datasets: [{ data: statusData.map(r => r.count), backgroundColor: [C.mint, C.violet, C.coral], borderColor: '#10182B', borderWidth: 3 }]
    },
    options: {
      responsive: true, maintainAspectRatio: false, cutout: '68%',
      plugins: { legend: { position: 'bottom', labels: { boxWidth: 10, usePointStyle: true, padding: 16 } } }
    }
  });

  const topDepts = DATA.top_departments_revenue;
  new Chart(document.getElementById('chartTopDepts'), {
    type: 'bar',
    data: {
      labels: topDepts.map(r => r.department_name),
      datasets: [{ data: topDepts.map(r => r.revenue), backgroundColor: topDepts.map((_, i) => PALETTE[i % PALETTE.length]), borderRadius: 4, barThickness: 18 }]
    },
    options: {
      indexAxis: 'y', responsive: true, maintainAspectRatio: false,
      plugins: { legend: { display: false }, tooltip: { callbacks: { label: ctx => fmtINR(ctx.parsed.x) } } },
      scales: { x: { grid: baseGrid, ticks: { ...baseTicks, callback: v => '₹' + (v / 1000) + 'k' } }, y: { grid: { display: false }, ticks: baseTicks } }
    }
  });

  const pm = DATA.payment_mode_summary;
  new Chart(document.getElementById('chartPaymentModeOverview'), {
    type: 'pie',
    data: { labels: pm.map(r => r.payment_mode), datasets: [{ data: pm.map(r => r.net_amount), backgroundColor: PALETTE, borderColor: '#10182B', borderWidth: 3 }] },
    options: {
      responsive: true, maintainAspectRatio: false,
      plugins: { legend: { position: 'bottom', labels: { boxWidth: 10, usePointStyle: true, padding: 16 } }, tooltip: { callbacks: { label: ctx => `${ctx.label}: ${fmtINR(ctx.parsed)}` } } }
    }
  });
})();

// ============================================================
// PATIENTS TAB
// ============================================================
(function () {
  const g = DATA.patient_gender;
  new Chart(document.getElementById('chartPatientGender'), {
    type: 'doughnut',
    data: { labels: g.map(r => r.gender), datasets: [{ data: g.map(r => r.count), backgroundColor: [C.violet, C.mint, C.gold], borderColor: '#10182B', borderWidth: 3 }] },
    options: { responsive: true, maintainAspectRatio: false, cutout: '65%', plugins: { legend: { position: 'bottom', labels: { boxWidth: 9, usePointStyle: true } } } }
  });

  const bg = DATA.patient_blood_group;
  new Chart(document.getElementById('chartBloodGroup'), {
    type: 'bar',
    data: { labels: bg.map(r => r.blood_group), datasets: [{ data: bg.map(r => r.count), backgroundColor: C.coralDim, borderColor: C.coral, borderWidth: 1.5, borderRadius: 4 }] },
    options: {
      responsive: true, maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: { x: { grid: { display: false }, ticks: baseTicks }, y: { grid: baseGrid, ticks: baseTicks } }
    }
  });

  const ins = DATA.insurance_providers;
  new Chart(document.getElementById('chartInsurance'), {
    type: 'doughnut',
    data: { labels: ins.map(r => r.provider), datasets: [{ data: ins.map(r => r.count), backgroundColor: PALETTE, borderColor: '#10182B', borderWidth: 3 }] },
    options: { responsive: true, maintainAspectRatio: false, cutout: '55%', plugins: { legend: { display: false } } }
  });

  const cities = DATA.top_patient_cities;
  new Chart(document.getElementById('chartTopCities'), {
    type: 'bar',
    data: { labels: cities.map(r => r.city), datasets: [{ data: cities.map(r => r.patient_count), backgroundColor: C.blueDim, borderColor: C.blue, borderWidth: 1.5, borderRadius: 4 }] },
    options: {
      responsive: true, maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: { x: { grid: { display: false }, ticks: { ...baseTicks, maxRotation: 40, minRotation: 40 } }, y: { grid: baseGrid, ticks: baseTicks } }
    }
  });

  const tp = DATA.top_patients_revenue;
  document.querySelector('#tblTopPatients tbody').innerHTML = tp.map(r => `
    <tr><td>${r.patient_name}</td><td>${r.city}</td><td class="right mono">${fmtINR(r.total_paid)}</td></tr>
  `).join('');

  // VIP table with sort + search
  makeSortableTable('tblVip', DATA.vip_patients, {
    patient_name: v => v,
    city: v => v,
    total_consultations: v => fmtNum(v),
    total_spend: v => fmtINR(v),
    avg_spend_per_visit: v => fmtINR(v),
  }, 'total_spend', 'desc', 'searchVip', ['patient_name', 'city']);
})();

// ============================================================
// DOCTORS & DEPARTMENTS TAB
// ============================================================
(function () {
  const spec = DATA.specialization_distribution.slice(0, 14);
  new Chart(document.getElementById('chartSpecializations'), {
    type: 'bar',
    data: { labels: spec.map(r => r.specialization), datasets: [{ data: spec.map(r => r.doctor_count), backgroundColor: C.violetDim, borderColor: C.violet, borderWidth: 1.5, borderRadius: 4 }] },
    options: {
      indexAxis: 'y', responsive: true, maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: { x: { grid: baseGrid, ticks: baseTicks }, y: { grid: { display: false }, ticks: { ...baseTicks, font: { size: 10.5 } } } }
    }
  });

  const ds = DATA.doctor_status;
  new Chart(document.getElementById('chartDoctorStatus'), {
    type: 'doughnut',
    data: { labels: ds.map(r => r.status), datasets: [{ data: ds.map(r => r.count), backgroundColor: [C.mint, C.gold, C.coral], borderColor: '#10182B', borderWidth: 3 }] },
    options: { responsive: true, maintainAspectRatio: false, cutout: '65%', plugins: { legend: { position: 'bottom', labels: { boxWidth: 9, usePointStyle: true } } } }
  });
  document.getElementById('statSeniorActive').textContent = fmtNum(DATA.senior_active_doctors.count);
  document.getElementById('statHighLoad').textContent = fmtNum(DATA.high_load_doctors_count.doctors_over_8_appts);

  const ef = DATA.doctor_experience_fee;
  const byStatus = { Active: [], 'On Leave': [], Retired: [] };
  ef.forEach(d => { (byStatus[d.status] || (byStatus[d.status] = [])).push({ x: d.experience_years, y: d.consultation_fee }); });
  new Chart(document.getElementById('chartExpFee'), {
    type: 'scatter',
    data: {
      datasets: [
        { label: 'Active', data: byStatus['Active'] || [], backgroundColor: C.mint },
        { label: 'On Leave', data: byStatus['On Leave'] || [], backgroundColor: C.gold },
        { label: 'Retired', data: byStatus['Retired'] || [], backgroundColor: C.coral },
      ]
    },
    options: {
      responsive: true, maintainAspectRatio: false,
      plugins: { legend: { position: 'top', labels: { boxWidth: 9, usePointStyle: true } } },
      scales: {
        x: { title: { display: true, text: 'Experience (years)', color: C.muted, font: { size: 11 } }, grid: baseGrid, ticks: baseTicks },
        y: { title: { display: true, text: 'Consultation Fee (₹)', color: C.muted, font: { size: 11 } }, grid: baseGrid, ticks: baseTicks },
      }
    }
  });

  const bvr = DATA.department_budget_vs_revenue.slice(0, 12);
  new Chart(document.getElementById('chartBudgetVsRevenue'), {
    type: 'bar',
    data: {
      labels: bvr.map(r => r.department_name),
      datasets: [
        { label: 'Budget Allocation', data: bvr.map(r => r.budget_allocation), backgroundColor: C.grid, borderColor: C.muted, borderWidth: 1, borderRadius: 3 },
        { label: 'Revenue Generated', data: bvr.map(r => r.revenue), backgroundColor: C.mintDim, borderColor: C.mint, borderWidth: 1, borderRadius: 3 },
      ]
    },
    options: {
      responsive: true, maintainAspectRatio: false,
      plugins: { legend: { position: 'top', labels: { boxWidth: 10, usePointStyle: true } }, tooltip: { callbacks: { label: ctx => `${ctx.dataset.label}: ${fmtINR(ctx.parsed.y)}` } } },
      scales: { x: { grid: { display: false }, ticks: { ...baseTicks, maxRotation: 45, minRotation: 45, font: { size: 9.5 } } }, y: { grid: baseGrid, ticks: { ...baseTicks, callback: v => '₹' + (v / 1000) + 'k' } } }
    }
  });

  makeSortableTable('tblDoctors', DATA.top_doctors_revenue, {
    full_name: v => v,
    specialization: v => v,
    department_name: v => v,
    total_appointments: v => fmtNum(v),
    total_revenue: v => fmtINR(v),
  }, 'total_revenue', 'desc', 'searchDoctors', ['full_name', 'specialization', 'department_name']);
})();

// ============================================================
// REVENUE & BILLING TAB
// ============================================================
(function () {
  const trend = DATA.monthly_revenue_trend.filter(r => r.mom_growth_pct !== null);
  new Chart(document.getElementById('chartMoM'), {
    type: 'line',
    data: {
      labels: trend.map(r => r.billing_month),
      datasets: [{
        data: trend.map(r => r.mom_growth_pct), borderColor: C.gold, backgroundColor: 'rgba(245,185,66,0.12)',
        fill: true, tension: 0.35, pointRadius: 2, pointBackgroundColor: C.gold, borderWidth: 2
      }]
    },
    options: {
      responsive: true, maintainAspectRatio: false,
      plugins: { legend: { display: false }, tooltip: { callbacks: { label: ctx => fmtPct(ctx.parsed.y) } } },
      scales: {
        x: { grid: { display: false }, ticks: { ...baseTicks, maxTicksLimit: 8 } },
        y: { grid: baseGrid, ticks: { ...baseTicks, callback: v => v + '%' } }
      }
    }
  });

  const rr = DATA.receivables_risk;
  new Chart(document.getElementById('chartReceivablesRisk'), {
    type: 'bar',
    data: {
      labels: rr.map(r => r.payment_mode),
      datasets: [{ data: rr.map(r => r.pending_risk_pct), backgroundColor: rr.map(r => r.pending_risk_pct > 15 ? C.coralDim : C.mintDim), borderColor: rr.map(r => r.pending_risk_pct > 15 ? C.coral : C.mint), borderWidth: 1.5, borderRadius: 4 }]
    },
    options: {
      responsive: true, maintainAspectRatio: false,
      plugins: { legend: { display: false }, tooltip: { callbacks: { label: ctx => `${fmtPct(ctx.parsed.y)} pending of net billed` } } },
      scales: { x: { grid: { display: false }, ticks: baseTicks }, y: { grid: baseGrid, ticks: { ...baseTicks, callback: v => v + '%' } } }
    }
  });

  new Chart(document.getElementById('chartBillingFunnel'), {
    type: 'bar',
    data: {
      labels: rr.map(r => r.payment_mode),
      datasets: [
        { label: 'Gross Billed', data: rr.map(r => r.gross_bill_amount), backgroundColor: C.violetDim, borderColor: C.violet, borderWidth: 1, borderRadius: 3 },
        { label: 'Discounts', data: rr.map(r => r.total_discount_given), backgroundColor: C.goldDim, borderColor: C.gold, borderWidth: 1, borderRadius: 3 },
        { label: 'Insurance Claimed', data: rr.map(r => r.total_insurance_claimed), backgroundColor: C.blueDim, borderColor: C.blue, borderWidth: 1, borderRadius: 3 },
        { label: 'Net Amount', data: rr.map(r => r.total_net_amount), backgroundColor: C.mintDim, borderColor: C.mint, borderWidth: 1, borderRadius: 3 },
      ]
    },
    options: {
      responsive: true, maintainAspectRatio: false,
      plugins: { legend: { position: 'top', labels: { boxWidth: 10, usePointStyle: true, font: { size: 10.5 } } }, tooltip: { callbacks: { label: ctx => `${ctx.dataset.label}: ${fmtINR(ctx.parsed.y)}` } } },
      scales: { x: { grid: { display: false }, ticks: baseTicks }, y: { grid: baseGrid, ticks: { ...baseTicks, callback: v => '₹' + (v / 1000) + 'k' } } }
    }
  });

  const ob = DATA.outstanding_bills_sample;
  document.querySelector('#tblOutstanding tbody').innerHTML = ob.map(r => `
    <tr>
      <td>${r.patient_name}</td>
      <td class="right mono">${fmtINR(r.net_amount)}</td>
      <td>${fmtDate(r.due_date)}</td>
      <td class="right mono" style="color:${r.days_overdue > 0 ? C.coral : C.muted}">${r.days_overdue > 0 ? r.days_overdue : 0}</td>
    </tr>
  `).join('');
})();

// ============================================================
// CLINICAL OPERATIONS TAB
// ============================================================
(function () {
  const ops = DATA.department_operations.slice(0, 12);
  new Chart(document.getElementById('chartDeptOps'), {
    type: 'bar',
    data: {
      labels: ops.map(r => r.department_name),
      datasets: [
        { label: 'Completed', data: ops.map(r => r.completed_count), backgroundColor: C.mint, stack: 's' },
        { label: 'Cancelled', data: ops.map(r => r.cancelled_count), backgroundColor: C.coral, stack: 's' },
        { label: 'Scheduled', data: ops.map(r => r.pending_count), backgroundColor: C.violet, stack: 's' },
      ]
    },
    options: {
      indexAxis: 'y', responsive: true, maintainAspectRatio: false,
      plugins: { legend: { position: 'top', labels: { boxWidth: 10, usePointStyle: true } } },
      scales: { x: { stacked: true, grid: baseGrid, ticks: baseTicks }, y: { stacked: true, grid: { display: false }, ticks: { ...baseTicks, font: { size: 10.5 } } } }
    }
  });

  document.getElementById('statReadmit').textContent = fmtNum(DATA.readmission_30d_count.readmissions_30d);

  const dx = DATA.top_diagnoses;
  new Chart(document.getElementById('chartDiagnoses'), {
    type: 'bar',
    data: { labels: dx.map(r => r.diagnosis), datasets: [{ data: dx.map(r => r.count), backgroundColor: C.coralDim, borderColor: C.coral, borderWidth: 1.5, borderRadius: 4 }] },
    options: {
      indexAxis: 'y', responsive: true, maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: { x: { grid: baseGrid, ticks: baseTicks }, y: { grid: { display: false }, ticks: { ...baseTicks, font: { size: 10.5 } } } }
    }
  });

  const meds = DATA.top_medications;
  new Chart(document.getElementById('chartMedications'), {
    type: 'bar',
    data: { labels: meds.map(r => `${r.generic_name}`), datasets: [{ data: meds.map(r => r.times_prescribed), backgroundColor: C.goldDim, borderColor: C.gold, borderWidth: 1.5, borderRadius: 4 }] },
    options: {
      indexAxis: 'y', responsive: true, maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: { x: { grid: baseGrid, ticks: baseTicks }, y: { grid: { display: false }, ticks: { ...baseTicks, font: { size: 10.5 } } } }
    }
  });

  const inp = DATA.active_inpatients_sample;
  document.querySelector('#tblInpatients tbody').innerHTML = inp.map(r => `
    <tr>
      <td>${r.patient_name}</td>
      <td>${fmtDate(r.admission_date)}</td>
      <td class="right mono">${r.stay_days}</td>
      <td>${r.attending_doctor}</td>
      <td>${r.department_name}</td>
    </tr>
  `).join('');
})();

// ============================================================
// Generic sortable + searchable table builder
// ============================================================
function makeSortableTable(tableId, rows, formatters, defaultKey, defaultDir, searchId, searchKeys) {
  const table = document.getElementById(tableId);
  const tbody = table.querySelector('tbody');
  const ths = table.querySelectorAll('thead th[data-key]');
  let sortKey = defaultKey, sortDir = defaultDir, filterText = '';

  function render() {
    let data = rows.slice();
    if (filterText) {
      const f = filterText.toLowerCase();
      data = data.filter(r => searchKeys.some(k => String(r[k]).toLowerCase().includes(f)));
    }
    data.sort((a, b) => {
      let va = a[sortKey], vb = b[sortKey];
      if (typeof va === 'string') { va = va.toLowerCase(); vb = vb.toLowerCase(); }
      if (va < vb) return sortDir === 'asc' ? -1 : 1;
      if (va > vb) return sortDir === 'asc' ? 1 : -1;
      return 0;
    });
    const keys = Object.keys(formatters);
    tbody.innerHTML = data.map(r => `<tr>${keys.map(k => {
      const isNum = typeof r[k] === 'number';
      return `<td class="${isNum ? 'right mono' : ''}">${formatters[k](r[k])}</td>`;
    }).join('')}</tr>`).join('') || `<tr><td colspan="${keys.length}" style="color:var(--muted-dim);">No matching rows</td></tr>`;
    ths.forEach(th => {
      th.querySelector('.arrow').textContent = th.dataset.key === sortKey ? (sortDir === 'asc' ? '↑' : '↓') : '↕';
    });
  }

  ths.forEach(th => {
    th.addEventListener('click', () => {
      const key = th.dataset.key;
      if (sortKey === key) { sortDir = sortDir === 'asc' ? 'desc' : 'asc'; }
      else { sortKey = key; sortDir = 'desc'; }
      render();
    });
  });

  if (searchId) {
    const input = document.getElementById(searchId);
    input.addEventListener('input', () => { filterText = input.value; render(); });
  }

  render();
}
