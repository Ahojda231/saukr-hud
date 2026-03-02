let aktualniRychlost = 0;
let cilRychlost = 0;
let aktualniOtacky = 0;
let cilOtacky = 0;

const prolni = (a, b, t) => a + (b - a) * t;
const MAX_RYCHLOST = 180;

const EL = {};
function napicej() {
    ['rpm-bar','fuel-bar','fuel-pct','fuel-icon',
     'gear-value','gear-box','compass','compass-direction',
     'location-info','location-street','location-zone',
     'speedometer',
     'ind-engine','ind-belt','ind-lights',
     'voice-card','stamina-card',
     'voice-dot-1','voice-dot-2','voice-dot-3'
    ].forEach(id => { EL[id] = document.getElementById(id); });
    EL.realDigits = document.querySelectorAll('#speed-value .speedo-real-d');
    EL.digitSlots = document.querySelectorAll('#speed-value .speedo-digit');
}
document.addEventListener('DOMContentLoaded', napicej);

function jakymSmerem(heading) {
    const n = ((heading % 360) + 360) % 360;
    if (n >= 337.5 || n < 22.5) return 'Sever';
    if (n >= 22.5 && n < 67.5) return 'Severovýchod';
    if (n >= 67.5 && n < 112.5) return 'Východ';
    if (n >= 112.5 && n < 157.5) return 'Jihovýchod';
    if (n >= 157.5 && n < 202.5) return 'Jih';
    if (n >= 202.5 && n < 247.5) return 'Jihozápad';
    if (n >= 247.5 && n < 292.5) return 'Západ';
    if (n >= 292.5 && n < 337.5) return 'Severozápad';
    return 'Sever';
}

function vykresliCislicka(speed) {
    const val = Math.min(Math.round(speed), 999);
    const digits = String(val).padStart(3, '0').split('');
    if (!EL.realDigits) return;
    EL.realDigits.forEach((slot, i) => {
        slot.textContent = digits[i];
        const isLeading = digits[i] === '0' && val < Math.pow(10, 2 - i);
        slot.style.color = isLeading ? 'transparent' : '';
    });
}

function tocSe() {
    if (Math.abs(cilRychlost - aktualniRychlost) > 0.2) {
        aktualniRychlost = prolni(aktualniRychlost, cilRychlost, 0.1);
    } else {
        aktualniRychlost = cilRychlost;
    }
    vykresliCislicka(aktualniRychlost);

    if (Math.abs(cilOtacky - aktualniOtacky) > 0.001) {
        aktualniOtacky = prolni(aktualniOtacky, cilOtacky, 0.12);
    } else {
        aktualniOtacky = cilOtacky;
    }
    if (EL['rpm-bar']) {
        EL['rpm-bar'].style.width = (aktualniOtacky * 100) + '%';
        EL['rpm-bar'].classList.toggle('redline', aktualniOtacky > 0.85);
    }
    requestAnimationFrame(tocSe);
}
tocSe();

window.addEventListener('message', function (event) {
    const data = event.data;

    if (data.action === 'updateStatus') {
        obnovLajsnu('health', data.health);
        obnovLajsnu('armor', data.armor);
        obnovLajsnu('hunger', data.hunger);
        obnovLajsnu('thirst', data.thirst);
        obnovLajsnu('stamina', data.stamina ?? 0);
        prepniStaminku(!!data.showStamina);
        obnovMikrofon(data.voice, data.isTalking);
    }

    if (data.action === 'toggleHud') {
        const wrap = document.getElementById('hud-wrap');
        if (wrap) wrap.style.display = data.show ? 'block' : 'none';
    }

    if (data.action === 'pauseOverlay') {
        document.getElementById('pause-overlay')?.classList.toggle('show', !!data.show);
    }

    if (data.action === 'vehicleEnter') {
        EL['speedometer']?.classList.add('show');
    }

    if (data.action === 'vehicleExit') {
        EL['speedometer']?.classList.remove('show');
        EL['compass']?.classList.remove('show');
        EL['location-info']?.classList.remove('show');
    }

    if (data.action === 'updateVehicleStatus') {
        obnovTachac(data);
    }
});

function obnovTachac(data) {
    cilRychlost = data.speed;
    cilOtacky = Math.min(data.speed / MAX_RYCHLOST, 1);

    if (data.heading !== undefined && EL['compass-direction']) {
        EL['compass-direction'].textContent = jakymSmerem(data.heading);
        EL['compass']?.classList.add('show');
    }

    if ((data.street || data.zone) && EL['location-info']) {
        if (EL['location-street']) EL['location-street'].textContent = data.street || 'Neznámá ulice';
        if (EL['location-zone'])  EL['location-zone'].textContent  = data.zone   || '';
        EL['location-info'].classList.add('show');
    }

    if (data.gear !== undefined && EL['gear-value']) {
        const g = data.gear;
        EL['gear-value'].textContent = g === 0 ? 'R' : String(g);
        EL['gear-box']?.classList.toggle('reverse', g === 0);
    }

    if (EL['ind-engine'] && data.engineHealth !== undefined) {
        const h = data.engineHealth;
        EL['ind-engine'].className = 'speedo-ind ' +
            (h < 300 ? 'ind-danger' : h < 650 ? 'ind-warn' : 'ind-ok');
    }
    if (EL['ind-belt'] && data.seatbelt !== undefined) {
        EL['ind-belt'].className = 'speedo-ind ' + (data.seatbelt ? 'ind-active' : 'ind-ok');
    }
    if (EL['ind-lights'] && data.lights !== undefined) {
        EL['ind-lights'].className = 'speedo-ind ' +
            (data.lights === 2 ? 'ind-high' : data.lights === 1 ? 'ind-active' : 'ind-ok');
    }

    if (EL['fuel-bar']) {
        const fuel = Math.max(0, Math.min(100, Math.round(data.fuel)));
        EL['fuel-bar'].style.height = fuel + '%';
        if (EL['fuel-pct']) EL['fuel-pct'].textContent = fuel + '%';
        const low = fuel < 20;
        EL['fuel-bar'].classList.toggle('low', low);
        EL['fuel-icon']?.classList.toggle('low', low);
    }
}

function obnovLajsnu(type, value) {
    if (value < 0) value = 0;
    if (value > 100) value = 100;
    const bar  = document.getElementById(type + '-bar');
    const pct  = document.getElementById(type + '-pct');
    const card = document.getElementById(type + '-card');
    if (bar) bar.style.width = value + '%';
    if (pct) pct.textContent = Math.round(value);
    if (type === 'armor' && card) {
        card.style.display = value <= 0 ? 'none' : 'flex';
    }
    const warnTypes = ['health', 'hunger', 'thirst', 'stamina'];
    if (card && warnTypes.includes(type)) {
        card.classList.toggle('warn', value < 25);
    }
}

function obnovMikrofon(level, isTalking) {
    const card = EL['voice-card'];
    const max  = Math.min(level || 2, 3);
    for (let i = 1; i <= 3; i++) {
        const dot = EL['voice-dot-' + i];
        if (!dot) continue;
        dot.style.background = i <= max
            ? (isTalking ? '#eab308' : 'rgba(255,255,255,0.7)')
            : 'rgba(255,255,255,0.15)';
    }
    card?.classList.toggle('talking', !!isTalking);
}

function prepniStaminku(show) {
    EL['stamina-card']?.classList.toggle('show', show);
}
