(function () {
    'use strict';

    // ── config ──────────────────────────────────────────────
    const NODE       = Proxmox.NodeName || 'pve';
    const REFRESH_MS = 5000;

    // layout constants (px)
    const HOST_R  = 48;   // host node radius
    const VM_R    = 38;   // vm/lxc node radius
    const VM_GAP  = 28;   // horizontal gap between vm nodes
    const TOP_PAD = 70;   // top margin to host center
    const BUS_GAP = 80;   // vertical distance from host bottom to bus line
    const LEG_GAP = 80;   // vertical distance from bus line to vm top

    // ── state ───────────────────────────────────────────────
    let dashActive   = false;
    let refreshTimer = null;
    let selectedVM   = null;

    // ── API ─────────────────────────────────────────────────
    async function fetchVMs() {
        const headers = { 'CSRFPreventionToken': Proxmox.CSRFPreventionToken };
        const [vmsRes, lxcRes] = await Promise.all([
            fetch(`/api2/json/nodes/${NODE}/qemu`, { credentials: 'include', headers }),
            fetch(`/api2/json/nodes/${NODE}/lxc`,  { credentials: 'include', headers }),
        ]);
        const vms = vmsRes.ok ? (await vmsRes.json()).data || [] : [];
        const lxc = lxcRes.ok ? (await lxcRes.json()).data || [] : [];
        return [
            ...vms.map(v => ({ ...v, type: 'qemu' })),
            ...lxc.map(v => ({ ...v, type: 'lxc'  })),
        ].sort((a, b) => a.vmid - b.vmid);
    }

    async function sendCommand(vmid, type, cmd) {
        await fetch(`/api2/json/nodes/${NODE}/${type}/${vmid}/status/${cmd}`, {
            method: 'POST',
            credentials: 'include',
            headers: { 'CSRFPreventionToken': Proxmox.CSRFPreventionToken },
        });
        setTimeout(renderTopology, 1500);
    }

    // ── layout ──────────────────────────────────────────────
    function calcLayout(vms, canvasW) {
        const hostCX = canvasW / 2;
        const hostCY = TOP_PAD + HOST_R;

        const vmDiam    = VM_R * 2;
        const totalVMW  = vms.length * vmDiam + Math.max(0, vms.length - 1) * VM_GAP;
        const startX    = Math.max(VM_R + 20, (canvasW - totalVMW) / 2 + VM_R);

        const busY  = hostCY + HOST_R + BUS_GAP;
        const vmCY  = busY + LEG_GAP + VM_R;

        const nodes = vms.map((vm, i) => ({
            ...vm,
            cx: startX + i * (vmDiam + VM_GAP),
            cy: vmCY,
        }));

        return { hostCX, hostCY, busY, nodes };
    }

    // ── SVG helpers ──────────────────────────────────────────
    function svgEl(tag, attrs) {
        const el = document.createElementNS('http://www.w3.org/2000/svg', tag);
        Object.entries(attrs).forEach(([k, v]) => el.setAttribute(k, v));
        return el;
    }

    function drawConnections(svg, hostCX, hostCY, busY, nodes) {
        const LINE_COLOR  = '#1e3a80';
        const DOT_COLOR   = '#3a60c0';
        const STROKE_W    = '1.5';

        // vertical stem from host bottom to bus
        svg.appendChild(svgEl('line', {
            x1: hostCX, y1: hostCY + HOST_R,
            x2: hostCX, y2: busY,
            stroke: LINE_COLOR, 'stroke-width': STROKE_W,
        }));

        if (!nodes.length) return;

        const leftX  = nodes[0].cx;
        const rightX = nodes[nodes.length - 1].cx;

        // horizontal bus
        svg.appendChild(svgEl('line', {
            x1: leftX, y1: busY, x2: rightX, y2: busY,
            stroke: LINE_COLOR, 'stroke-width': STROKE_W,
        }));

        // dot where host stem meets bus
        svg.appendChild(svgEl('circle', {
            cx: hostCX, cy: busY, r: 3.5,
            fill: DOT_COLOR,
        }));

        nodes.forEach(node => {
            // vertical leg from bus to node top
            svg.appendChild(svgEl('line', {
                x1: node.cx, y1: busY,
                x2: node.cx, y2: node.cy - VM_R,
                stroke: LINE_COLOR, 'stroke-width': STROKE_W,
            }));

            // junction dot on bus for each node
            svg.appendChild(svgEl('circle', {
                cx: node.cx, cy: busY, r: 3,
                fill: DOT_COLOR,
            }));
        });
    }

    // ── render ───────────────────────────────────────────────
    async function renderTopology() {
        const canvas = document.getElementById('topology-canvas');
        if (!canvas) return;

        let vms;
        try {
            vms = await fetchVMs();
        } catch (e) {
            canvas.innerHTML = '<div class="topo-loading">API CONNECTION ERROR</div>';
            return;
        }

        window._customVMData = vms;

        // update header stats
        const running = vms.filter(v => v.status === 'running').length;
        const stopped = vms.filter(v => v.status === 'stopped').length;
        const statsEl = document.getElementById('custom-dash-stats');
        if (statsEl) {
            statsEl.innerHTML =
                `NODE: ${NODE} &nbsp;&nbsp;` +
                `<span style="color:#4a8fd9">● ${running} RUNNING</span> &nbsp;` +
                `<span style="color:#8b3030">● ${stopped} STOPPED</span>`;
        }

        // canvas dimensions
        const canvasW = Math.max(
            canvas.offsetWidth || window.innerWidth,
            vms.length * (VM_R * 2 + VM_GAP) + 120
        );
        const canvasH = canvas.offsetHeight || (window.innerHeight - 64);

        // clear and rebuild
        canvas.innerHTML = '';
        canvas.style.minWidth = canvasW + 'px';

        const { hostCX, hostCY, busY, nodes } = calcLayout(vms, canvasW);

        // SVG layer (behind nodes)
        const svg = svgEl('svg', {
            width: canvasW, height: canvasH,
            style: 'position:absolute;top:0;left:0;pointer-events:none;',
        });
        canvas.appendChild(svg);

        drawConnections(svg, hostCX, hostCY, busY, nodes);

        // host node
        const hostEl = document.createElement('div');
        hostEl.className = 'topo-node host';
        hostEl.style.cssText =
            `left:${hostCX}px;top:${hostCY}px;` +
            `width:${HOST_R * 2}px;height:${HOST_R * 2}px;`;
        hostEl.innerHTML =
            `<div class="node-name">${NODE.toUpperCase()}</div>` +
            `<div class="node-type">PROXMOX</div>`;
        canvas.appendChild(hostEl);

        // vm/lxc nodes
        nodes.forEach(vm => {
            const el = document.createElement('div');
            el.className = `topo-node ${vm.status}`;
            el.style.cssText =
                `left:${vm.cx}px;top:${vm.cy}px;` +
                `width:${VM_R * 2}px;height:${VM_R * 2}px;`;
            el.innerHTML =
                `<div class="node-name">${vm.name || 'VM-' + vm.vmid}</div>` +
                `<div class="node-id">#${vm.vmid}</div>` +
                `<div class="node-type">${vm.type}</div>`;
            el.onclick = () => customDashSelectVM(vm.vmid, vm.type);
            canvas.appendChild(el);
        });
    }

    // ── popup ────────────────────────────────────────────────
    window.customDashSelectVM = function (vmid, type) {
        const vm = (window._customVMData || []).find(v => v.vmid === vmid);
        if (!vm) return;
        selectedVM = vm;

        const popup   = document.getElementById('custom-vm-popup');
        const overlay = document.getElementById('popup-overlay');

        document.getElementById('popup-vm-name').textContent   = vm.name || 'VM-' + vmid;
        document.getElementById('popup-vm-id').textContent     = vm.vmid;
        document.getElementById('popup-vm-type').textContent   = vm.type === 'lxc' ? 'Container LXC' : 'Virtual Machine';
        document.getElementById('popup-vm-status').textContent = vm.status.toUpperCase();

        const cpuPct = vm.cpu != null ? (vm.cpu * 100).toFixed(1) + '%  (' + (vm.cpus || '-') + ' vCPU)' : (vm.cpus || '-') + ' vCPU';
        document.getElementById('popup-vm-cpu').textContent = cpuPct;

        const ramUsed = vm.mem    ? (vm.mem    / 1073741824).toFixed(1) : null;
        const ramMax  = vm.maxmem ? (vm.maxmem / 1073741824).toFixed(1) : null;
        document.getElementById('popup-vm-ram').textContent =
            ramUsed && ramMax ? ramUsed + ' / ' + ramMax + ' GB' : (ramMax ? ramMax + ' GB' : '-');

        document.getElementById('popup-vm-disk').textContent   = vm.maxdisk ? (vm.maxdisk / 1073741824).toFixed(1) + ' GB' : '-';

        const uptimeSec = vm.uptime || 0;
        const uptimeStr = uptimeSec > 0
            ? (Math.floor(uptimeSec / 86400) > 0 ? Math.floor(uptimeSec / 86400) + 'd ' : '') +
              Math.floor((uptimeSec % 86400) / 3600) + 'h ' +
              Math.floor((uptimeSec % 3600)  / 60)   + 'm'
            : '-';
        document.getElementById('popup-vm-uptime').textContent = uptimeStr;

        document.getElementById('popup-btn-start').style.opacity  = vm.status === 'running' ? '0.3' : '1';
        document.getElementById('popup-btn-stop').style.opacity   = vm.status === 'stopped'  ? '0.3' : '1';
        document.getElementById('popup-btn-reboot').style.opacity = vm.status !== 'running'  ? '0.3' : '1';

        popup.classList.add('active');
        overlay.classList.add('active');
    };

    window.customDashClosePopup = function () {
        document.getElementById('custom-vm-popup').classList.remove('active');
        document.getElementById('popup-overlay').classList.remove('active');
        selectedVM = null;
    };

    window.customDashCommand = function (cmd) {
        if (!selectedVM) return;
        if (cmd === 'start'  && selectedVM.status === 'running') return;
        if (cmd === 'stop'   && selectedVM.status === 'stopped') return;
        if (cmd === 'reboot' && selectedVM.status !== 'running') return;
        sendCommand(selectedVM.vmid, selectedVM.type, cmd);
        customDashClosePopup();
    };

    // ── DOM builders ─────────────────────────────────────────
    function buildDashboard() {
        const dash = document.createElement('div');
        dash.id = 'custom-dashboard';
        dash.innerHTML = `
            <div class="dash-header">
                <div>
                    <div class="dash-title">DIMANET - NETWORK MAP</div>
                    <div class="dash-subtitle">PROXMOX VE &middot; ${NODE.toUpperCase()}</div>
                </div>
                <div class="dash-stats" id="custom-dash-stats">LOADING...</div>
            </div>
            <div id="topology-canvas">
                <div class="topo-loading">LOADING...</div>
            </div>
        `;
        document.body.appendChild(dash);

        const popup = document.createElement('div');
        popup.id = 'custom-vm-popup';
        popup.innerHTML = `
            <h3 id="popup-vm-name">VM NAME</h3>
            <div class="popup-row"><span class="popup-label">ID</span>     <span class="popup-value" id="popup-vm-id">-</span></div>
            <div class="popup-row"><span class="popup-label">TYPE</span>   <span class="popup-value" id="popup-vm-type">-</span></div>
            <div class="popup-row"><span class="popup-label">STATUS</span> <span class="popup-value" id="popup-vm-status">-</span></div>
            <div class="popup-row"><span class="popup-label">CPU</span>    <span class="popup-value" id="popup-vm-cpu">-</span></div>
            <div class="popup-row"><span class="popup-label">RAM</span>    <span class="popup-value" id="popup-vm-ram">-</span></div>
            <div class="popup-row"><span class="popup-label">DISK</span>   <span class="popup-value" id="popup-vm-disk">-</span></div>
            <div class="popup-row"><span class="popup-label">UPTIME</span> <span class="popup-value" id="popup-vm-uptime">-</span></div>
            <div class="popup-actions">
                <button id="popup-btn-start"  class="popup-btn start"  onclick="customDashCommand('start')">&#9654; START</button>
                <button id="popup-btn-stop"   class="popup-btn stop"   onclick="customDashCommand('stop')">&#9632; STOP</button>
                <button id="popup-btn-reboot" class="popup-btn reboot" onclick="customDashCommand('reboot')">&#8635; REBOOT</button>
                <button class="popup-btn close" onclick="customDashClosePopup()">&#10005;</button>
            </div>
        `;
        document.body.appendChild(popup);

        const overlay = document.createElement('div');
        overlay.id = 'popup-overlay';
        overlay.onclick = customDashClosePopup;
        document.body.appendChild(overlay);
    }

    function buildToggleBtn() {
        const btn = document.createElement('div');
        btn.id = 'custom-toggle-btn';
        btn.innerHTML = '<div class="toggle-dot"></div><span>MAP</span>';
        btn.title = 'Network Map dashboard';
        btn.onclick = toggleDashboard;
        document.body.appendChild(btn);
    }

    function toggleDashboard() {
        dashActive = !dashActive;
        const dash = document.getElementById('custom-dashboard');
        const label = document.querySelector('#custom-toggle-btn span');

        const dot = document.querySelector('#custom-toggle-btn .toggle-dot');
        if (dashActive) {
            dash.classList.add('active');
            label.textContent = 'PROXMOX';
            if (dot) dot.style.background = '#50e890';
            renderTopology();
            refreshTimer = setInterval(renderTopology, REFRESH_MS);
        } else {
            dash.classList.remove('active');
            label.textContent = 'MAP';
            if (dot) dot.style.background = '#4a8fd9';
            customDashClosePopup();
            clearInterval(refreshTimer);
        }
    }

    // ── init ─────────────────────────────────────────────────
    function init() {
        buildDashboard();
        buildToggleBtn();
        document.addEventListener('keydown', function (e) {
            if (e.key === 'Escape') customDashClosePopup();
        });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => setTimeout(init, 1500));
    } else {
        setTimeout(init, 1500);
    }

})();
