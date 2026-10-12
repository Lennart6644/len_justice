(() => {
    'use strict';

    const RESOURCE = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'punish';
    const SVG_NS = 'http://www.w3.org/2000/svg';
    const THEMES = ['theme-jail', 'theme-comserv', 'theme-admin'];

    const UNIT_KEYS = {
        pending: 'ui.row_units',
        jailed: 'ui.row_units',
        comserv: 'ui.row_hours',
        adminjailed: 'ui.row_minutes',
    };

    const LISTS = {
        pending: { container: 'pending-items', empty: 'ui.empty_pending' },
        jailed: { container: 'jailed-items', empty: 'ui.empty_jailed' },
        comserv: { container: 'comserv-items', empty: 'ui.empty_comserv' },
        adminjailed: { container: 'admin-items', empty: 'ui.empty_admin' },
    };

    const SECTIONS = [
        {
            key: 'jail', label: 'ui.nav_jail', icon: 'lock', theme: 'theme-jail', mode: 'justice',
            views: [
                { id: 'jail-create', label: 'ui.tab_jail_create', icon: 'gavel', perm: ['canJudge'] },
                { id: 'jail-pending', label: 'ui.tab_jail_pending', icon: 'list', perm: ['canJail'], kind: 'pending' },
                { id: 'jail-release', label: 'ui.tab_jail_release', icon: 'key', perm: ['canRelease'] },
            ],
        },
        {
            key: 'jailed', label: 'ui.nav_jailed', icon: 'users', theme: 'theme-jail', mode: 'justice',
            views: [
                { id: 'list-jailed', label: 'ui.nav_jailed', icon: 'users', perm: ['canJail', 'canJudge'], kind: 'jailed' },
            ],
        },
        {
            key: 'comserv', label: 'ui.nav_comserv', icon: 'broom', theme: 'theme-comserv', mode: 'justice',
            views: [
                { id: 'comserv-assign', label: 'ui.tab_comserv_assign', icon: 'broom', perm: ['canComServ'] },
                { id: 'comserv-revoke', label: 'ui.tab_comserv_revoke', icon: 'check', perm: ['canUnComServ'] },
            ],
        },
        {
            key: 'comservlist', label: 'ui.nav_comserv_list', icon: 'users', theme: 'theme-comserv', mode: 'justice',
            views: [
                { id: 'list-comserv', label: 'ui.nav_comserv_list', icon: 'users', perm: ['canComServ', 'canUnComServ'], kind: 'comserv' },
            ],
        },
        {
            key: 'admin', label: 'ui.nav_admin', icon: 'shield', theme: 'theme-admin', mode: 'admin',
            views: [
                { id: 'admin-assign', label: 'ui.tab_admin_assign', icon: 'alert', perm: ['isAdmin'] },
                { id: 'admin-revoke', label: 'ui.tab_admin_revoke', icon: 'check', perm: ['isAdmin'] },
                { id: 'admin-list', label: 'ui.tab_admin_list', icon: 'list', perm: ['isAdmin'], kind: 'adminjailed' },
            ],
        },
    ];

    const state = {
        mode: 'justice',
        perms: {},
        limits: {},
        strings: {},
        section: null,
        busy: false,
    };

    const app = document.getElementById('app');
    const panel = document.getElementById('panel');
    const nav = document.getElementById('nav');
    const subnav = document.getElementById('subnav');
    const titleEl = document.getElementById('title');
    const badgeEl = document.getElementById('badge');
    const hud = document.getElementById('hud');
    const hudTitle = document.getElementById('hud-title');
    const hudValue = document.getElementById('hud-value');
    const hudUnit = document.getElementById('hud-unit');
    const hudIcon = document.getElementById('hud-icon');
    const hudFill = document.getElementById('hud-fill');
    const hudAfk = document.getElementById('hud-afk');

    const t = key => (state.strings[key] !== undefined ? state.strings[key] : key);
    const fmt = (key, ...args) => t(key).replace(/%[ds]/g, () => String(args.shift() ?? ''));

    const el = (tag, className, text) => {
        const node = document.createElement(tag);
        if (className) node.className = className;
        if (text !== undefined) node.textContent = text;
        return node;
    };

    const iconEl = (name, className = 'icon') => {
        const svg = document.createElementNS(SVG_NS, 'svg');
        svg.setAttribute('class', className);
        const use = document.createElementNS(SVG_NS, 'use');
        use.setAttribute('href', `#i-${name}`);
        svg.appendChild(use);
        return svg;
    };

    const post = (endpoint, body = {}) => fetch(`https://${RESOURCE}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(body),
    }).then(r => r.json()).catch(() => null);

    const allowed = view => view.perm.some(p => state.perms[p]);
    const allViews = () => SECTIONS.flatMap(section => section.views);
    const findView = id => allViews().find(view => view.id === id);
    const visibleSections = () => SECTIONS.filter(section => section.mode === state.mode && section.views.some(allowed));

    const applyI18n = () => {
        document.querySelectorAll('[data-i18n]').forEach(node => {
            node.textContent = t(node.dataset.i18n);
        });
        document.querySelectorAll('[data-i18n-placeholder]').forEach(node => {
            node.placeholder = t(node.dataset.i18nPlaceholder);
        });
        document.querySelectorAll('[data-limit-label]').forEach(node => {
            node.textContent = fmt('ui.limit', state.limits[node.dataset.limitLabel] || 0);
        });
    };

    const setTheme = theme => {
        panel.classList.remove(...THEMES);
        panel.classList.add(theme);
    };

    const renderNav = () => {
        nav.replaceChildren();
        visibleSections().forEach(section => {
            const btn = el('button', 'nav-btn');
            btn.dataset.section = section.key;
            btn.append(iconEl(section.icon), el('span', null, t(section.label)));
            btn.addEventListener('click', () => activateSection(section.key));
            nav.append(btn);
        });
    };

    const renderSubnav = views => {
        subnav.replaceChildren();
        subnav.classList.toggle('hidden', views.length < 2);
        views.forEach(view => {
            const btn = el('button', 'subnav-btn');
            btn.dataset.view = view.id;
            btn.append(iconEl(view.icon), el('span', null, t(view.label)));
            btn.addEventListener('click', () => activateView(view.id));
            subnav.append(btn);
        });
    };

    const validateView = view => {
        if (!view) return;
        let valid = true;
        view.querySelectorAll('[data-field]').forEach(input => {
            const raw = input.value.trim();
            let ok;
            if (input.type === 'number') {
                const n = Number(raw);
                const max = input.dataset.limit
                    ? Number(state.limits[input.dataset.limit] || 0)
                    : Number(input.dataset.max || Infinity);
                ok = raw !== '' && Number.isInteger(n) && n >= 1 && n <= max;
            } else {
                ok = raw.length > 0;
            }
            input.classList.toggle('invalid', !ok && raw !== '');
            if (!ok) valid = false;
        });
        const action = view.querySelector('[data-action]');
        if (action) action.disabled = !valid;
    };

    const collectFields = view => {
        const data = {};
        view.querySelectorAll('[data-field]').forEach(input => {
            data[input.dataset.field] = input.value.trim();
        });
        return data;
    };

    const clearFields = view => {
        view.querySelectorAll('[data-field]').forEach(input => {
            input.value = '';
            input.classList.remove('invalid');
        });
    };

    const buildRow = (row, kind) => {
        const item = el('div', 'row-item');
        const info = el('div', 'row-info');
        info.append(el('strong', 'row-name', row.name || t('ui.unknown')));

        const meta = el('div', 'row-meta');
        meta.append(el('span', 'chip chip-accent', fmt(UNIT_KEYS[kind], row.amount)));
        if (row.reason) meta.append(el('span', 'chip', fmt('ui.row_reason', row.reason)));
        if (row.judge) meta.append(el('span', 'chip', fmt('ui.row_by', row.judge)));
        if (row.date) meta.append(el('span', 'chip muted', fmt('ui.row_since', row.date)));
        info.append(meta);
        item.append(info);

        if (kind === 'pending') {
            const btn = el('button', 'btn primary small', t('ui.btn_execute'));
            btn.dataset.action = 'jail_execute';
            btn.dataset.id = row.id;
            item.append(btn);
        }
        return item;
    };

    const loadList = kind => {
        const target = LISTS[kind];
        if (!target) return;
        const container = document.getElementById(target.container);
        container.replaceChildren(el('div', 'placeholder', t('ui.loading')));

        post('fetch', { kind }).then(rows => {
            const items = Array.isArray(rows) ? rows : [];
            if (!items.length) {
                container.replaceChildren(el('div', 'placeholder', t(target.empty)));
                return;
            }
            container.replaceChildren(...items.map((row, index) => {
                const node = buildRow(row, kind);
                node.style.setProperty('--i', index);
                return node;
            }));
        });
    };

    const activateView = id => {
        const view = findView(id);
        if (!view) return;

        document.querySelectorAll('.view').forEach(node => {
            node.classList.toggle('active', node.id === `view-${id}`);
        });
        subnav.querySelectorAll('.subnav-btn').forEach(btn => {
            btn.classList.toggle('active', btn.dataset.view === id);
        });

        validateView(document.getElementById(`view-${id}`));
        if (view.kind) loadList(view.kind);
    };

    const activateSection = key => {
        const section = SECTIONS.find(s => s.key === key);
        if (!section) return;
        const views = section.views.filter(allowed);
        if (!views.length) return;

        state.section = key;
        setTheme(section.theme);
        nav.querySelectorAll('.nav-btn').forEach(btn => {
            btn.classList.toggle('active', btn.dataset.section === key);
        });
        renderSubnav(views);
        activateView(views[0].id);
    };

    const sendAction = (btn, action, payload) => {
        if (state.busy) return;
        state.busy = true;
        btn.classList.add('is-busy');

        post('action', { action, payload }).then(() => {
            setTimeout(() => {
                state.busy = false;
                btn.classList.remove('is-busy');

                const view = btn.closest('.view');
                if (!view) return;
                clearFields(view);
                const found = findView(view.id.replace('view-', ''));
                if (found && found.kind) loadList(found.kind);
                validateView(view);
            }, 400);
        });
    };

    const openUI = data => {
        state.mode = data.mode === 'admin' ? 'admin' : 'justice';
        state.perms = data.perms || {};
        state.limits = data.limits || {};
        state.strings = data.strings || {};
        state.section = null;

        applyI18n();
        titleEl.textContent = t(state.mode === 'admin' ? 'ui.title_admin' : 'ui.title_justice');
        badgeEl.textContent = t(state.mode === 'admin' ? 'ui.role_admin' : 'ui.role_justice');
        renderNav();

        app.classList.remove('hidden', 'closing');
        const first = visibleSections()[0];
        if (first) activateSection(first.key);
    };

    const detailsApp = document.getElementById('details-app');

    const openDetails = data => {
        state.strings = data.strings || state.strings;
        applyI18n();
        document.getElementById('details-units').textContent = data.data.units;
        document.getElementById('details-date').textContent = data.data.date;
        document.getElementById('details-reason').textContent = data.data.reason;
        document.getElementById('details-judge').textContent = data.data.judge;
        detailsApp.classList.remove('hidden', 'closing');
    };

    const closeDetails = () => {
        if (detailsApp.classList.contains('hidden')) return;
        detailsApp.classList.add('closing');
        setTimeout(() => {
            detailsApp.classList.add('hidden');
            detailsApp.classList.remove('closing');
        }, 260);
        post('detailsClosed');
        post('close');
    };

    const closeUI = () => {
        if (!detailsApp.classList.contains('hidden')) return closeDetails();
        if (app.classList.contains('hidden')) return;
        app.classList.add('closing');
        setTimeout(() => {
            app.classList.add('hidden');
            app.classList.remove('closing');
        }, 260);
        document.querySelectorAll('.view').forEach(clearFields);
        post('close');
    };

    document.getElementById('details-close').addEventListener('click', closeDetails);

    const updateHud = msg => {
        if (!msg.show || !msg.data) {
            if (hud.classList.contains('hidden') || hud.classList.contains('out')) return;
            hud.classList.add('out');
            setTimeout(() => {
                if (hud.classList.contains('out')) {
                    hud.classList.add('hidden');
                    hud.classList.remove('out');
                }
            }, 320);
            return;
        }

        const d = msg.data;
        hud.classList.remove('hidden', 'out', ...THEMES);
        hud.classList.add(`theme-${d.theme}`);

        hudTitle.textContent = d.title || '';
        hudUnit.textContent = d.unit || '';
        hudIcon.setAttribute('href', `#i-${d.icon || 'lock'}`);

        if (hudValue.textContent !== String(d.value)) {
            hudValue.textContent = d.value;
            hudValue.classList.remove('pop');
            void hudValue.offsetWidth;
            hudValue.classList.add('pop');
        }

        const pct = d.total > 0 ? Math.max(0, Math.min(100, (d.value / d.total) * 100)) : 0;
        hudFill.style.width = `${pct}%`;

        hudAfk.textContent = d.afk ? (d.afkText || '') : '';
        hudAfk.classList.toggle('visible', !!d.afk);
    };

    document.addEventListener('click', event => {
        const refresh = event.target.closest('[data-refresh]');
        if (refresh) {
            loadList(refresh.dataset.refresh);
            return;
        }

        const btn = event.target.closest('[data-action]');
        if (!btn || btn.disabled || state.busy) return;

        const view = btn.closest('.view');
        const payload = btn.dataset.action === 'jail_execute'
            ? { id: Number(btn.dataset.id) }
            : collectFields(view);

        sendAction(btn, btn.dataset.action, payload);
    });

    document.addEventListener('input', event => {
        const view = event.target.closest('.view');
        if (view) validateView(view);
    });

    document.getElementById('close-btn').addEventListener('click', closeUI);

    document.addEventListener('keydown', event => {
        if (event.key === 'Escape') closeUI();
    });

    window.addEventListener('message', event => {
        const data = event.data;
        if (!data || !data.action) return;
        if (data.action === 'open') openUI(data);
        else if (data.action === 'details') openDetails(data);
        else if (data.action === 'hud') updateHud(data);
    });
})();
