# -*- coding: utf-8 -*-
"""
BLM4522 Proje 5 - ETL icin kirli veri seti uretici.
staging_customers tablosuna uygun, kasitli bozukluklar icerir.
"""
import csv
import random
from faker import Faker

fake = Faker("tr_TR")
Faker.seed(42)
random.seed(42)

N = 1000
rows = []
# Bozuklugu raporlamak icin sayaclar
stats = {
    "duplicate": 0, "bad_email": 0, "bad_date": 0,
    "null_name": 0, "whitespace": 0, "city_case": 0,
    "bad_id": 0, "messy_phone": 0,
}

cities = ["Istanbul", "Ankara", "Izmir", "Bursa", "Antalya", "Adana", "Konya"]

def messy_city(c):
    # Sehir adini rastgele buyuk/kucuk harf + bosluk karmasasi
    style = random.choice(["upper", "lower", "title", "space", "normal"])
    if style == "upper": return c.upper()
    if style == "lower": return c.lower()
    if style == "title": return c.title()
    if style == "space": return "  " + c + " "
    return c

def messy_phone():
    # Telefon formatlari kasitli tutarsiz
    n = fake.msisdn()[-10:]
    fmt = random.choice([
        f"0{n}", f"+90{n}", f"0 {n[:3]} {n[3:6]} {n[6:]}",
        f"({n[:3]}) {n[3:6]}-{n[6:]}", n,
    ])
    return fmt

def make_date():
    d = fake.date_between(start_date="-5y", end_date="today")
    r = random.random()
    if r < 0.12:  # %12 bozuk tarih
        stats["bad_date"] += 1
        bad = random.choice([
            d.strftime("%d/%m/%Y"),      # 104 formatina uymayan
            d.strftime("%m-%d-%Y"),      # ABD formati
            "32/13/2023",                # gecersiz gun/ay
            "",                          # bos
            "bilinmiyor",                # metin
        ])
        return bad
    # Gecerli ama format MSSQL 104 (dd.mm.yyyy) -> bunu temizlikte cevireceksin
    return d.strftime("%d.%m.%Y")

base_id = 1000
for i in range(N):
    base_id += 1
    cid = str(base_id)
    name = fake.name()
    email = fake.email()
    city = random.choice(cities)
    date = make_date()
    phone = fake.phone_number()

    # --- Kasitli bozukluklar ---
    # Bozuk email (~%10)
    if random.random() < 0.10:
        stats["bad_email"] += 1
        email = random.choice([
            email.replace("@", ""), email.replace(".", ""),
            "gecersiz_email", name.split()[0].lower() + "@", "@domain.com",
        ])

    # Null/bos isim (~%5)
    if random.random() < 0.05:
        stats["null_name"] += 1
        name = ""

    # Bosluklu isim (~%15)
    elif random.random() < 0.15:
        stats["whitespace"] += 1
        name = "  " + name + "   "

    # Sehir buyuk/kucuk karmasasi (cogunlukla)
    mc = messy_city(city)
    if mc != city:
        stats["city_case"] += 1
    city = mc

    # Bozuk id (~%3) -> sayisal degil
    if random.random() < 0.03:
        stats["bad_id"] += 1
        cid = random.choice(["ABC" + cid, cid + "x", ""])

    # Karisik telefon
    phone = messy_phone()
    stats["messy_phone"] += 1

    rows.append([cid, name, email, city, date, phone])

# Duplicate kayitlar ekle (~%5) - ayni email tekrar
dup_count = int(N * 0.05)
for _ in range(dup_count):
    src = random.choice(rows[:N])
    dup = src.copy()
    base_id += 1
    dup[0] = str(base_id)  # farkli id, ayni email -> duplicate tespiti
    rows.append(dup)
    stats["duplicate"] += 1

random.shuffle(rows)

# UTF-8 BOM ile yaz (MSSQL BULK INSERT Turkce karakter icin)
with open("/home/claude/customers_raw.csv", "w", encoding="utf-8-sig", newline="") as f:
    w = csv.writer(f, delimiter=",", quoting=csv.QUOTE_MINIMAL)
    w.writerow(["id", "full_name", "email", "city", "signup_date", "phone"])
    w.writerows(rows)

print(f"Toplam satir (header haric): {len(rows)}")
print("--- Kasitli bozukluk istatistikleri ---")
for k, v in stats.items():
    print(f"  {k:12s}: {v}")
