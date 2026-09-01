# nosleep

Jednoduchý skript, který nechá Mac vzhůru i se zavřeným víkem. Žádná appka, žádný Mac mini doma. Jeden příkaz.

Proč to vzniklo: ovládám Claude Code na svým Macu vzdáleně z mobilu. Jenže jakmile zavřete víko, Mac usne a je po zábavě. Řešení lidí okolo mě? Nosit otevřenej notebook po nádraží, nebo doma provozovat Mac mini, co nikdy nespí. Za mě zbytečný. macOS to umí sám, jen to nemá žádný rozumný tlačítko.

`nosleep` je tenký obal nad systémovým `pmset disablesleep`. Nic víc. Ale ten rozdíl v pohodlí je boží.

## Instalace

```bash
sudo curl -fsSL https://raw.githubusercontent.com/dolezal-td/nosleep/main/nosleep -o /usr/local/bin/nosleep && sudo chmod +x /usr/local/bin/nosleep
```

Nebo si stáhněte soubor `nosleep`, hoďte ho kamkoli do `PATH` a dejte mu `chmod +x`.

## Použití

```bash
nosleep            # přepne stav (on ↔ off)
nosleep on         # zakáže uspání
nosleep on 3h      # zakáže uspání, po 3 hodinách se samo vrátí do normálu
nosleep off        # obnoví normální uspávání
nosleep status     # vypíše aktuální stav
```

Délka pojistky jde zapsat jako `3h`, `90m` nebo holé sekundy (`10800`).

Skript volá `sudo`, takže se první spuštění zeptá na heslo. Účet musí být admin.

## Časovaná pojistka

`nosleep on 3h` je můj oblíbený režim. Zakážete uspání, odejdete, a nemusíte si pamatovat, že to máte večer vypnout. Po uplynutí času se Mac sám vrátí k normálnímu uspávání.

Pojistka běží jen do restartu Macu. Když mezitím restartujete, spusťte `nosleep off` ručně (nebo se koukněte na `nosleep status`).

## Vzdálené ovládání bez hesla (volitelné)

Pokud Mac ovládáte na dálku (SSH, Claude Code z mobilu), hodí se, aby `pmset` nechtěl heslo. Přidejte si pravidlo do sudoers:

```bash
echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/pmset" | sudo tee /etc/sudoers.d/pmset
```

Povoluje bez hesla jen `pmset`, nic jiného. Kdo to nepotřebuje, ať to nedělá.

## Na co si dát pozor

- **Mac v batohu.** Zavřený neuspaný Mac topí. Nedávejte ho s aktivním `nosleep` do batohu nebo pouzdra, může se přehřát.
- **Baterie.** `disablesleep` platí i na baterii. Mac bez napájení prostě pojede, dokud nedojde šťáva. Proto existuje ta časovaná pojistka. :)
- **Ověření stavu.** Kdykoli si nejste jistí: `nosleep status`, nebo natvrdo `pmset -g | grep SleepDisabled` (1 = uspání zakázáno).

## Jak to funguje

Celé kouzlo je jeden systémový příkaz:

```bash
sudo pmset -a disablesleep 1   # Mac neusne, ani se zavřeným víkem
sudo pmset -a disablesleep 0   # zpátky do normálu
```

Skript k tomu přidává přepínání, výpis stavu a časovanou pojistku. To je všecko.

## Licence

MIT. Berte, upravujte, sdílejte.

---

*English: a tiny zsh wrapper around macOS `pmset disablesleep` that keeps your Mac awake with the lid closed — handy for remote-controlling it (e.g. Claude Code from your phone). `nosleep on 3h` disables sleep with an automatic revert after 3 hours. Requires an admin account (`sudo`). Careful: an awake Mac in a backpack gets hot, and `disablesleep` also applies on battery.*
