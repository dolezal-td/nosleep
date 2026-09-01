# nosleep

Jednoduchý skript, který nechá počítač vzhůru i se zavřeným víkem. Žádná appka, žádný proces na pozadí, žádný Mac mini doma. Jeden statický přepínač v systému.

Proč to vzniklo: ovládám Claude Code na svým Macu vzdáleně z mobilu. Jenže jakmile zavřete víko, Mac usne a je po zábavě. Řešení lidí okolo mě? Nosit otevřenej notebook po nádraží, nebo doma provozovat Mac mini, co nikdy nespí. Za mě zbytečný. Systém to umí sám, jen to nemá žádný rozumný tlačítko.

Funguje na macOS (zsh skript) i Windows (PowerShell).

## Instalace přes coding agenta (doporučená cesta)

Máte Claude Code, Codex nebo jiného coding agenta? Pak je instalátor jedna věta:

> Nainstaluj mi nosleep z https://github.com/dolezal-td/nosleep a ověř, že funguje.

Agent si v repu přečte [AGENTS.md](AGENTS.md), pozná váš systém, skript vám nejdřív shrne (ať víte, co pouštíte), nainstaluje ho a ověří. Umí ho i odinstalovat.

## Ruční instalace — macOS

Bez sudo, do vaší uživatelské složky:

```bash
mkdir -p ~/.local/bin && curl -fsSL https://raw.githubusercontent.com/dolezal-td/nosleep/main/nosleep -o ~/.local/bin/nosleep && chmod +x ~/.local/bin/nosleep
```

Pokud `~/.local/bin` nemáte v PATH, přidejte si do `~/.zshrc` řádek `export PATH="$HOME/.local/bin:$PATH"`. A kdo cizím one-linerům z internetu nevěří (správně!), ať si soubor [nosleep](nosleep) prostě přečte a stáhne ručně, je to 100 řádků.

## Ruční instalace — Windows

Stáhněte [windows/nosleep.ps1](windows/nosleep.ps1) kamkoli (třeba `%LOCALAPPDATA%\nosleep\`) a spouštějte z PowerShellu **jako správce**. Detaily a napojení na příkaz `nosleep` v profilu najdete v [AGENTS.md](AGENTS.md) — přesně tohle za vás jinak udělá agent.

## Použití

```bash
nosleep            # přepne stav (on ↔ off)
nosleep on         # zakáže uspání
nosleep on 3h      # zakáže uspání, po 3 hodinách se samo vrátí do normálu
nosleep off        # obnoví normální uspávání (a zruší běžící pojistku)
nosleep status     # vypíše aktuální stav
```

Délka pojistky jde zapsat jako `3h`, `90m` nebo holé sekundy (`10800`). Na Macu skript volá `sudo` (účet musí být admin), na Windows chce PowerShell spuštěný jako správce.

## Časovaná pojistka

`nosleep on 3h` je můj oblíbený režim. Zakážete uspání, odejdete, a nemusíte si pamatovat, že to máte večer vypnout. Po uplynutí času se počítač sám vrátí k normálnímu uspávání.

- Nové `nosleep on` nebo `off` vždy zruší předchozí pojistku. Nikdy neběží dvě proti sobě.
- Na Macu pojistka běží jen do restartu. **Samotný zákaz uspání ale restart přežije** — je to statický přepínač v systému. Když si nejste jistí, `nosleep status` řekne pravdu.
- Na Windows pojistka běží přes Plánovač úloh, takže přežije i restart.

## Proč ne caffeinate nebo Amphetamine?

Otázka, která přijde vždycky. Tak popořadě:

**`caffeinate` zavřené víko nevyřeší. Vůbec.** Funguje přes power assertions — běžící proces si drží „zámek" proti usnutí z nečinnosti. Jenže zavření víka je jiná, hardwarová cesta k uspání, kterou žádná assertion nepřebije. Spustíte `caffeinate`, zavřete víko, Mac stejně usne. Jediné, co zavřené víko řeší, je právě `pmset disablesleep`. ([podrobné vysvětlení](https://clamshell.dev/guides/why-caffeinate-does-not-work-lid-closed))

**Amphetamine to umí, ale jako běžící GUI aplikace se sessions.** Když appka neběží, neběží nic. Na Apple Silicon k tomu potřebuje [pomocný skript s admin právy](https://iffy.freshdesk.com/support/solutions/articles/48001077199-amphetamine-closed-display-mode) a existuje celá kategorie podpory pro [tiše selhané sessions](https://iffy.freshdesk.com/support/solutions/articles/48001180528-about-failed-closed-display-mode-sessions) při přepojení napájení. A ze SSH nebo z coding agenta ji neovládáte.

`nosleep` dělá jedinou věc: přepne statický řádek v nastavení napájení. Žádný proces, žádná session, nic, co může spadnout nebo tiše selhat. Stav si kdykoli ověříte jedním příkazem a přesně proto to funguje vzdáleně. Druhá strana téže mince: přepnuté to zůstane, dokud to nepřepnete zpátky (i přes restart) — od toho je pojistka.

## Vzdálené ovládání bez hesla (volitelné, macOS)

Pokud Mac ovládáte na dálku (SSH, coding agent z mobilu), hodí se, aby `sudo pmset` nechtěl heslo. Povolte bez hesla **jen ty dva konkrétní příkazy**, které skript používá — nic víc. A přes `visudo`, které ohlídá syntax (rozbitý sudoers soubor umí zablokovat sudo na celém Macu):

```bash
sudo visudo -f /etc/sudoers.d/pmset
```

Do souboru vložte (za USERNAME doplňte své uživatelské jméno, zjistíte ho příkazem `whoami`):

```
USERNAME ALL=(ALL) NOPASSWD: /usr/bin/pmset -a disablesleep 1, /usr/bin/pmset -a disablesleep 0
```

Skript s tím počítá: pojistka si sama vybere, jestli poběží pod rootem (interaktivní použití), nebo přes tohle úzké pravidlo (vzdálené použití). Kdo to nepotřebuje, ať to nedělá.

## Na co si dát pozor

- **Počítač v batohu.** Zavřený neuspaný stroj topí. Nedávejte ho s aktivním `nosleep` do batohu nebo pouzdra, může se přehřát.
- **Baterie.** Zákaz uspání platí i na baterii. Bez napájení stroj prostě pojede, dokud nedojde šťáva. Proto existuje ta časovaná pojistka. :)
- **Restart nepomůže (macOS).** `disablesleep` je trvalé systémové nastavení, restart ho nevypne. Vypne ho jedině `nosleep off`.
- **Ověření stavu.** Kdykoli si nejste jistí: `nosleep status`, nebo na Macu natvrdo `pmset -g | grep SleepDisabled` (1 = uspání zakázáno).

## Jak to funguje

macOS — celé kouzlo je jeden systémový příkaz:

```bash
sudo pmset -a disablesleep 1   # Mac neusne, ani se zavřeným víkem
sudo pmset -a disablesleep 0   # zpátky do normálu
```

Windows — dvě hodnoty v aktivním schématu napájení přes `powercfg`: akce při zavření víka („nedělat nic") a časovač uspání („nikdy"). Původní hodnoty si skript uloží a při `off` vrátí přesně to, co jste měli.

Skript k tomu přidává přepínání, výpis stavu a časovanou pojistku. To je všecko.

## Licence

MIT. Berte, upravujte, sdílejte.

---

*English: a tiny dependency-free tool that keeps your computer awake with the lid closed — by flipping static power settings, with no background process. macOS: zsh wrapper around `pmset disablesleep`. Windows: PowerShell script setting lid-close action + sleep timeout via `powercfg`, with exact restore of your original values. `nosleep on 3h` auto-reverts after 3 hours. Needs sudo/admin. Agent-friendly: point your coding agent at this repo and it installs via [AGENTS.md](AGENTS.md). Careful: an awake laptop in a bag gets hot, and on macOS the flag survives reboots.*
