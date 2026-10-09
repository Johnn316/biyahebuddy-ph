# Sources

Every law, fine, hotline and coding rule shipped in `assets/data/` must have an
official source listed here before demo day. Entries in the JSON prefixed with
`SAMPLE` are placeholders and are **not verified**.

Owner: Devin (data). Reviewers: John, backend teammate.

## Laws (`laws.json`)

| id | Law / section | Official URL | Retrieved (date) |
|---|---|---|---|
| SAMPLE-ra4136-35 | RA 4136, Sec. 35 | TODO | |
| SAMPLE-ra10913-4 | RA 10913, Sec. 4 | TODO | |
| SAMPLE-ra8750-4 | RA 8750, Sec. 4 | TODO | |

## Fines (`fines.json`)

| Violation | Agency | Legal basis | Official URL | Retrieved |
|---|---|---|---|---|
| Driving without a valid license | LTO | LTO JAO 2014-01 | TODO | |
| Using mobile phone while driving | LTO | RA 10913 | TODO | |
| Number coding (UVVRP) | MMDA | MMDA Reg. 96-005 | TODO | |
| Illegal parking | City | City ordinance | TODO | |

## Hotlines (`hotlines.json`)

Retrieved 2026-10-09. `mmda.gov.ph`, `hpg.pnp.gov.ph`, `e911.gov.ph` and
`officialgazette.gov.ph` return HTTP 403 (Cloudflare bot check) to scripts and
to the automated browser, so those pages were read from Internet Archive
snapshots of the official URL (snapshot link in the table).

| Name | Number | Zone | Official source | Retrieved |
|---|---|---|---|---|
| Emergency 911 National Hotline | 911 | nationwide | Executive Order No. 56, s. 2018, Sec. 1 ("911 is hereby institutionalized as the Nationwide Emergency Hotline Number"). Official Gazette is blocked; text read from https://lawphil.net/executive/execord/eo2018/eo_56_2018.html | 2026-10-09 |
| Philippine Red Cross Emergency Hotline | 143 | nationwide | https://redcross.org.ph/ (site header: "Emergency Hotline: 143") | 2026-10-09 |
| PNP Highway Patrol Group (HPG) - Public Information Office | 02-8535-1931 | nationwide | https://hpg.pnp.gov.ph/ (press-release footer: "EMAIL/TEL NO: (02) 8535-1931"). Snapshot: https://web.archive.org/web/20251105013328/https://hpg.pnp.gov.ph/ | 2026-10-09 |
| MMDA Hotline | 136 | NCR | https://mmda.gov.ph/ (footer: "MMDA Hotline: 136"). Snapshot: https://web.archive.org/web/20251124055826/https://mmda.gov.ph/ | 2026-10-09 |
| NLEX Hotline (NLEX Corporation) | 1-35000 | NLEX | https://www.nlex.com.ph/contact-us ("Hotline: 1-35000") | 2026-10-09 |
| SCTEX Hotline (NLEX Corporation) | 1-35000 | SCTEX | https://www.nlex.com.ph/concessions (NLEX Corporation operates SCTEX under a BCDA contract; the site-wide hotline is 1-35000) | 2026-10-09 |
| SBMA Emergency - Rescue/Law Enforcement (Smart & Globe mobile) | 9111 | SBMA | SBMA Telephone Directory, "Emergency Hotline Numbers": https://www.mysubicbay.com.ph/upload/file/20230718-062804-1432.pdf (linked from https://www.mysubicbay.com.ph/how-to-reach-us/directory) | 2026-10-09 |
| SBMA Emergency - Rescue/Law Enforcement (Subictel landline) | 911 | SBMA | same SBMA directory | 2026-10-09 |
| SBMA Fire | 160 | SBMA | same SBMA directory | 2026-10-09 |
| SBMA Medical Emergency (Sagip Buhay) | 161 | SBMA | same SBMA directory | 2026-10-09 |
| SBMA Public Health & Safety - Emergency Trunkline | 047-252-4169 | SBMA | same SBMA directory ("Main Trunkline/Emergency 252-4169"; area code 047 from the site footer "+6347 252 4000") | 2026-10-09 |

Caveats:

- **PNP-HPG:** the official site publishes no 24/7 public hotline. The only
  phone number it lists is the HPG Public Information Office line, so that is
  the number used here. For emergencies on any highway, use 911.
- **SCTEX:** NLEX Corporation lists one hotline for all its expressways. It
  does not publish a separate SCTEX number.
- **SBMA:** the directory says 911 works from Subictel landlines and 9111 from
  Smart/Globe mobiles. It doesn't say which networks can reach 160 and 161. The
  directory PDF was uploaded 2023-07-18.

## Number coding (`coding.json`)

| Item | Official source | Retrieved |
|---|---|---|
| Scheme, hours (7:00-10:00 AM and 5:00-8:00 PM, weekdays except holidays), day/digit pairs, exempt vehicles, "LGU ordinances prevail on secondary roads" | MMDA press release PR-22-08-069, "MMDA to Reimplement Number Coding Scheme from 7-10am and 5-8pm on August 15" (Aug. 11, 2022; MMDA Resolution No. 22-14, s. 2022): https://mmda.gov.ph/84-news/news-2022/5749-aug-11-2022-mmda-to-reimplement-number-coding-scheme-from-7-10am-and-5-8pm-on-august-15.html. Snapshot: https://web.archive.org/web/20220812030029/https://mmda.gov.ph/84-news/news-2022/5749-aug-11-2022-mmda-to-reimplement-number-coding-scheme-from-7-10am-and-5-8pm-on-august-15.html | 2026-10-09 |
| Legal basis "MMDA Regulation No. 96-005, as amended" | MMDA Memorandum Circular No. 04 (2010), titled "...Exemptions from the UVVRP under MMDA Regulation No. 96-005, as amended": https://mmda.gov.ph/19-legal-matters/mmda-memorandum-circulars/265-2010-memorandum-circular-no-04-revised-guidelines-on-the-issuance-of-exemptions-from-the-unified-vehicular-volume-reduction-program-uvvrp-under-mmda-regulation-no-96-005-as-amended.html | 2026-10-09 |

Is it still current? `mmda.gov.ph` can't be reached directly (Cloudflare). On
2026-10-09 the Internet Archive index of `mmda.gov.ph` had no MMDA page about
number coding newer than a March 2023 one-day suspension, and nothing that
replaces the August 2022 rules. Recheck the MMDA site by hand before demo day.
**Exempt roads:** the MMDA release lists none. `exempt_roads` is empty, and the
notes say that city ordinances apply on secondary roads.

`coding.json` adds optional fields to the schema in CLAUDE.md: `legal_basis`,
`effective` (ISO date), `holidays_exempt` (bool), `exempt_vehicles`
([string]) and `exempt_roads` ([string]). Loaders can ignore them.
