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

One row per `fines.json` entry, in the same order. `amount` is a single PHP value, so
violations with escalating penalties get one row per offense tier (the tier is in
`violation`). Non-monetary penalties (suspension, seminar, impounding) are noted in
`violation`/`legal_basis`.

Notes:
- **LTO:** the current schedule is DOTr-LTO-LTFRB Joint Administrative Order No. 2014-01,
  declared valid by the Supreme Court in G.R. No. 206486 (Aug. 16, 2022). The JAO PDF on
  lto.gov.ph sits behind a Cloudflare bot check and has no Internet Archive copy, so only
  JAO rows whose amount is quoted in an accessible official text (the SC decision) are
  included. LTO rows for helmet, distracted driving, child safety, and DUI come from
  the Republic Acts LTO enforces (Sec. citations per Act).
- **MMDA:** Single Ticketing System = Metro Manila Traffic Code of 2023 (Joint Metro Manila
  Traffic Circular No. 01, s. 2023, adopted by MMDA Resolution No. 23-02). Illegal parking
  uses the ₱4,000 penalty from JMMTC No. 01, s. 2024, which removed the attended/unattended
  split. Copies are from the UP Law Center Office of the National Administrative Register
  (mmda.gov.ph is Cloudflare-blocked).
- **City (sample): Quezon City** Ordinance No. SP-3172, S-2023, which adopts the 2023
  Metro Manila Traffic Code. It still has the original attended (₱1,000) / unattended
  (₱2,000) parking fines; no QC ordinance adopting the 2024 ₱4,000 amendment was found.

| # | Violation | Agency | Legal basis | Official URL(s) | Retrieved |
|---|---|---|---|---|---|
| 1 | Driving without a valid driver's license or conductor's permit | LTO | JAO No. 2014-01, Rule I(a) (fine + 1-year disqualification from getting a license); JAO upheld in Republic v. Maria Basa Express Jeepney Operators, G.R. No. 206486, Aug. 16, 2022 | https://lto.gov.ph/wp-content/uploads/2023/09/JAO_2014-01.pdf<br>https://elibrary.judiciary.gov.ph/thebookshelf/showdocs/1/68571 | 2026-10-09 |
| 2 | No / non-standard motorcycle helmet — 1st offense | LTO | RA 10054 (Motorcycle Helmet Act of 2009), Sec. 7 | https://lawphil.net/statutes/repacts/ra2010/ra_10054_2010.html | 2026-10-09 |
| 3 | No / non-standard motorcycle helmet — 2nd offense | LTO | RA 10054 (Motorcycle Helmet Act of 2009), Sec. 7 | https://lawphil.net/statutes/repacts/ra2010/ra_10054_2010.html | 2026-10-09 |
| 4 | No / non-standard motorcycle helmet — 3rd offense | LTO | RA 10054 (Motorcycle Helmet Act of 2009), Sec. 7 | https://lawphil.net/statutes/repacts/ra2010/ra_10054_2010.html | 2026-10-09 |
| 5 | No / non-standard motorcycle helmet — 4th offense and subsequent (+ license confiscation) | LTO | RA 10054 (Motorcycle Helmet Act of 2009), Sec. 7 | https://lawphil.net/statutes/repacts/ra2010/ra_10054_2010.html | 2026-10-09 |
| 6 | Distracted driving (mobile phone / gadget use) — 1st offense | LTO | RA 10913 (Anti-Distracted Driving Act), Sec. 8 | https://lawphil.net/statutes/repacts/ra2016/ra_10913_2016.html | 2026-10-09 |
| 7 | Distracted driving (mobile phone / gadget use) — 2nd offense | LTO | RA 10913 (Anti-Distracted Driving Act), Sec. 8 | https://lawphil.net/statutes/repacts/ra2016/ra_10913_2016.html | 2026-10-09 |
| 8 | Distracted driving (mobile phone / gadget use) — 3rd offense (+ 3-month license suspension) | LTO | RA 10913 (Anti-Distracted Driving Act), Sec. 8 | https://lawphil.net/statutes/repacts/ra2016/ra_10913_2016.html | 2026-10-09 |
| 9 | Distracted driving (mobile phone / gadget use) — 4th offense and succeeding (+ license revocation) | LTO | RA 10913 (Anti-Distracted Driving Act), Sec. 8 | https://lawphil.net/statutes/repacts/ra2016/ra_10913_2016.html | 2026-10-09 |
| 10 | Distracted driving by a public utility, school service, or hazardous-cargo vehicle driver, or within 50 m of a school | LTO | RA 10913 (Anti-Distracted Driving Act), Sec. 8 (+ 3-month license suspension) | https://lawphil.net/statutes/repacts/ra2016/ra_10913_2016.html | 2026-10-09 |
| 11 | No child restraint system / child under 12 in front seat — 1st offense | LTO | RA 11229 (Child Safety in Motor Vehicles Act), Sec. 10 | https://lawphil.net/statutes/repacts/ra2019/ra_11229_2019.html | 2026-10-09 |
| 12 | No child restraint system / child under 12 in front seat — 2nd offense | LTO | RA 11229 (Child Safety in Motor Vehicles Act), Sec. 10 | https://lawphil.net/statutes/repacts/ra2019/ra_11229_2019.html | 2026-10-09 |
| 13 | No child restraint system / child under 12 in front seat — 3rd offense and subsequent (+ 1-year license suspension) | LTO | RA 11229 (Child Safety in Motor Vehicles Act), Sec. 10 | https://lawphil.net/statutes/repacts/ra2019/ra_11229_2019.html | 2026-10-09 |
| 14 | Child passenger on motorcycle in prohibited conditions — 1st offense | LTO | RA 10666 (Children's Safety on Motorcycles Act), Sec. 6 | https://lawphil.net/statutes/repacts/ra2015/ra_10666_2015.html | 2026-10-09 |
| 15 | Child passenger on motorcycle in prohibited conditions — 2nd offense | LTO | RA 10666 (Children's Safety on Motorcycles Act), Sec. 6 | https://lawphil.net/statutes/repacts/ra2015/ra_10666_2015.html | 2026-10-09 |
| 16 | Child passenger on motorcycle in prohibited conditions — 3rd offense (+ 1-month license suspension) | LTO | RA 10666 (Children's Safety on Motorcycles Act), Sec. 6 | https://lawphil.net/statutes/repacts/ra2015/ra_10666_2015.html | 2026-10-09 |
| 17 | Driving under the influence of alcohol/drugs, no injury (minimum fine; up to ₱80,000 + 3 months jail) | LTO | RA 10586 (Anti-Drunk and Drugged Driving Act), Sec. 12(a) | https://lawphil.net/statutes/repacts/ra2013/ra_10586_2013.html | 2026-10-09 |
| 18 | Disregarding traffic signs (incl. beating the red light) | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 10 | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 19 | Illegal parking (attended or unattended; vehicle may be impounded) | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 11.3, as amended by JMMTC No. 01, s. 2024 | https://naro.law.upd.edu.ph/storage/01JTQ7ZM5P8YDXPW4GH8CHSZ6X.pdf<br>https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 20 | Number coding (UVVRP) violation | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 12 | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 21 | Truck ban violation | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 13 | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 22 | Light truck ban violation | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 14 | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 23 | Reckless driving — 1st offense | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 15 | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 24 | Reckless driving — 2nd offense (+ driver's seminar) | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 15 | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 25 | Reckless driving — 3rd offense and subsequent (+ driver's seminar) | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 15 | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 26 | Tricycle ban violation | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 16 | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 27 | Obstruction of traffic | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 17 | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 28 | Motorcycle dress code violation (slippers, sando/shorts) — 1st offense | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 18 | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 29 | Motorcycle dress code violation (slippers, sando/shorts) — 2nd offense | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 18 | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 30 | Motorcycle dress code violation (slippers, sando/shorts) — 3rd offense | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 18 | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 31 | Overloading (passengers or cargo) | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 19 | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 32 | Defective motor vehicle accessories (lights, mirrors, horn) | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 20 | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 33 | Unauthorized modification of motor vehicle | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 21 | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 34 | Arrogance / discourteous conduct by driver (+ driver's seminar) | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 22 | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 35 | Loading/unloading in a prohibited zone | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 23 | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 36 | Illegal counterflow | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 24 | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 37 | Illegal counterflow causing physical injury or property damage | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 24 | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 38 | Overspeeding | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 25 | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 39 | No seatbelt (driver/front passenger) — 1st offense | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 26 (RA 8750) | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 40 | No seatbelt (driver/front passenger) — 2nd offense | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 26 (RA 8750) | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 41 | No seatbelt (driver/front passenger) — 3rd offense and subsequent (+ 1-week license suspension) | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 26 (RA 8750) | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 42 | No / non-standard motorcycle helmet — 1st offense | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 28 (RA 10054) | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 43 | No / non-standard motorcycle helmet — 2nd offense | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 28 (RA 10054) | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 44 | No / non-standard motorcycle helmet — 3rd offense | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 28 (RA 10054) | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 45 | No / non-standard motorcycle helmet — 4th offense and subsequent | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 28 (RA 10054) | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 46 | Distracted driving (mobile phone / gadget use) — 1st offense | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 30 (RA 10913) | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 47 | Distracted driving (mobile phone / gadget use) — 2nd offense | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 30 (RA 10913) | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 48 | Distracted driving (mobile phone / gadget use) — 3rd offense (+ 3-month license suspension) | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 30 (RA 10913) | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 49 | Distracted driving (mobile phone / gadget use) — 4th offense and succeeding (+ license revocation) | MMDA | Metro Manila Traffic Code of 2023 (JMMTC No. 01, s. 2023; MMDA Res. No. 23-02), Sec. 30 (RA 10913) | https://naro.law.upd.edu.ph/storage/01JN5638QBVRSKKSECPRRSXDRE.pdf<br>https://naro.law.upd.edu.ph/issuances/745<br>https://naro.law.upd.edu.ph/issuances/744 | 2026-10-09 |
| 50 | Disregarding traffic signs (incl. beating the red light) | City (Quezon City) | Quezon City Ordinance No. SP-3172, S-2023 (Revised Traffic Management Code), Sec. 10 | https://quezoncity.gov.ph/wp-content/uploads/2023/09/SP-3172-S-2023.pdf | 2026-10-09 |
| 51 | Illegal parking, attended by the driver | City (Quezon City) | Quezon City Ordinance No. SP-3172, S-2023 (Revised Traffic Management Code), Sec. 11 | https://quezoncity.gov.ph/wp-content/uploads/2023/09/SP-3172-S-2023.pdf | 2026-10-09 |
| 52 | Illegal parking, unattended (+ impoundment) | City (Quezon City) | Quezon City Ordinance No. SP-3172, S-2023 (Revised Traffic Management Code), Sec. 11 | https://quezoncity.gov.ph/wp-content/uploads/2023/09/SP-3172-S-2023.pdf | 2026-10-09 |
| 53 | Number coding (UVVRP) violation | City (Quezon City) | Quezon City Ordinance No. SP-3172, S-2023 (Revised Traffic Management Code), Sec. 12 | https://quezoncity.gov.ph/wp-content/uploads/2023/09/SP-3172-S-2023.pdf | 2026-10-09 |
| 54 | Truck ban violation | City (Quezon City) | Quezon City Ordinance No. SP-3172, S-2023 (Revised Traffic Management Code), Sec. 13 | https://quezoncity.gov.ph/wp-content/uploads/2023/09/SP-3172-S-2023.pdf | 2026-10-09 |
| 55 | Reckless driving — 1st offense | City (Quezon City) | Quezon City Ordinance No. SP-3172, S-2023 (Revised Traffic Management Code), Sec. 15 | https://quezoncity.gov.ph/wp-content/uploads/2023/09/SP-3172-S-2023.pdf | 2026-10-09 |
| 56 | Reckless driving — 2nd offense (+ driver's seminar) | City (Quezon City) | Quezon City Ordinance No. SP-3172, S-2023 (Revised Traffic Management Code), Sec. 15 | https://quezoncity.gov.ph/wp-content/uploads/2023/09/SP-3172-S-2023.pdf | 2026-10-09 |
| 57 | Reckless driving — 3rd offense and subsequent (+ driver's seminar) | City (Quezon City) | Quezon City Ordinance No. SP-3172, S-2023 (Revised Traffic Management Code), Sec. 15 | https://quezoncity.gov.ph/wp-content/uploads/2023/09/SP-3172-S-2023.pdf | 2026-10-09 |
| 58 | Obstruction of traffic | City (Quezon City) | Quezon City Ordinance No. SP-3172, S-2023 (Revised Traffic Management Code), Sec. 17 | https://quezoncity.gov.ph/wp-content/uploads/2023/09/SP-3172-S-2023.pdf | 2026-10-09 |
| 59 | Loading/unloading in a prohibited zone | City (Quezon City) | Quezon City Ordinance No. SP-3172, S-2023 (Revised Traffic Management Code), Sec. 23 | https://quezoncity.gov.ph/wp-content/uploads/2023/09/SP-3172-S-2023.pdf | 2026-10-09 |
| 60 | Illegal counterflow | City (Quezon City) | Quezon City Ordinance No. SP-3172, S-2023 (Revised Traffic Management Code), Sec. 24 | https://quezoncity.gov.ph/wp-content/uploads/2023/09/SP-3172-S-2023.pdf | 2026-10-09 |
| 61 | Illegal counterflow causing physical injury or property damage | City (Quezon City) | Quezon City Ordinance No. SP-3172, S-2023 (Revised Traffic Management Code), Sec. 24 | https://quezoncity.gov.ph/wp-content/uploads/2023/09/SP-3172-S-2023.pdf | 2026-10-09 |
| 62 | Overspeeding | City (Quezon City) | Quezon City Ordinance No. SP-3172, S-2023 (Revised Traffic Management Code), Sec. 25 | https://quezoncity.gov.ph/wp-content/uploads/2023/09/SP-3172-S-2023.pdf | 2026-10-09 |
| 63 | No seatbelt (driver/front passenger) — 1st offense | City (Quezon City) | Quezon City Ordinance No. SP-3172, S-2023 (Revised Traffic Management Code), Sec. 26 | https://quezoncity.gov.ph/wp-content/uploads/2023/09/SP-3172-S-2023.pdf | 2026-10-09 |
| 64 | No seatbelt (driver/front passenger) — 2nd offense | City (Quezon City) | Quezon City Ordinance No. SP-3172, S-2023 (Revised Traffic Management Code), Sec. 26 | https://quezoncity.gov.ph/wp-content/uploads/2023/09/SP-3172-S-2023.pdf | 2026-10-09 |
| 65 | No seatbelt (driver/front passenger) — 3rd offense and subsequent (+ 1-week license suspension) | City (Quezon City) | Quezon City Ordinance No. SP-3172, S-2023 (Revised Traffic Management Code), Sec. 26 | https://quezoncity.gov.ph/wp-content/uploads/2023/09/SP-3172-S-2023.pdf | 2026-10-09 |
| 66 | No / non-standard motorcycle helmet — 1st offense | City (Quezon City) | Quezon City Ordinance No. SP-3172, S-2023 (Revised Traffic Management Code), Sec. 28 | https://quezoncity.gov.ph/wp-content/uploads/2023/09/SP-3172-S-2023.pdf | 2026-10-09 |
| 67 | No / non-standard motorcycle helmet — 2nd offense | City (Quezon City) | Quezon City Ordinance No. SP-3172, S-2023 (Revised Traffic Management Code), Sec. 28 | https://quezoncity.gov.ph/wp-content/uploads/2023/09/SP-3172-S-2023.pdf | 2026-10-09 |
| 68 | No / non-standard motorcycle helmet — 3rd offense | City (Quezon City) | Quezon City Ordinance No. SP-3172, S-2023 (Revised Traffic Management Code), Sec. 28 | https://quezoncity.gov.ph/wp-content/uploads/2023/09/SP-3172-S-2023.pdf | 2026-10-09 |
| 69 | No / non-standard motorcycle helmet — 4th offense and subsequent | City (Quezon City) | Quezon City Ordinance No. SP-3172, S-2023 (Revised Traffic Management Code), Sec. 28 | https://quezoncity.gov.ph/wp-content/uploads/2023/09/SP-3172-S-2023.pdf | 2026-10-09 |
| 70 | Distracted driving (mobile phone / gadget use) — 1st offense | City (Quezon City) | Quezon City Ordinance No. SP-3172, S-2023 (Revised Traffic Management Code), Sec. 30 | https://quezoncity.gov.ph/wp-content/uploads/2023/09/SP-3172-S-2023.pdf | 2026-10-09 |
| 71 | Distracted driving (mobile phone / gadget use) — 2nd offense | City (Quezon City) | Quezon City Ordinance No. SP-3172, S-2023 (Revised Traffic Management Code), Sec. 30 | https://quezoncity.gov.ph/wp-content/uploads/2023/09/SP-3172-S-2023.pdf | 2026-10-09 |
| 72 | Distracted driving (mobile phone / gadget use) — 3rd offense (+ 3-month license suspension) | City (Quezon City) | Quezon City Ordinance No. SP-3172, S-2023 (Revised Traffic Management Code), Sec. 30 | https://quezoncity.gov.ph/wp-content/uploads/2023/09/SP-3172-S-2023.pdf | 2026-10-09 |
| 73 | Distracted driving (mobile phone / gadget use) — 4th offense and succeeding (+ license revocation) | City (Quezon City) | Quezon City Ordinance No. SP-3172, S-2023 (Revised Traffic Management Code), Sec. 30 | https://quezoncity.gov.ph/wp-content/uploads/2023/09/SP-3172-S-2023.pdf | 2026-10-09 |

## Hotlines (`hotlines.json`)

| Name | Number | Official URL | Retrieved |
|---|---|---|---|
| National Emergency Hotline | 911 | TODO | |
| Philippine Red Cross | 143 | TODO | |
| MMDA Metrobase | 136 | TODO | |

## Number coding (`coding.json`)

| Scheme | Official URL | Retrieved |
|---|---|---|
| MMDA UVVRP | TODO | |
