# -*- coding: utf-8 -*-
"""
=====================================================================
PROJE 3 - Dosya 07: SQL Injection Testi (Python demo)
PDF gereksinimi: "SQL injection saldirilarina karsi veritabaninin korunmasi."

Bu script AYNI giris islemini iki sekilde yapar:
  1) ACIK (vulnerable)  : kullanici girdisi sorguya string olarak eklenir -> ENJEKSIYON MUMKUN
  2) GUVENLI (safe)     : parametreli sorgu (%s) kullanilir            -> ENJEKSIYON ENGELLENIR

Calistirma:
  $env:PGPASSWORD="Banka2025"; python 07_sql_injection_demo.py
=====================================================================
"""
import os
import sys
import psycopg2

BAGLANTI = dict(
    host="localhost",
    dbname="guvenlik_db",
    user="postgres",
    password=os.environ.get("PGPASSWORD", "Banka2025"),
)

CIZGI = "=" * 70


def acik_giris(conn, kullanici_adi, parola):
    """ZAFIYETLI: Kullanici girdisini dogrudan SQL metnine gomer."""
    sorgu = (
        "SELECT kullanici_adi, rol FROM kullanicilar "
        f"WHERE kullanici_adi = '{kullanici_adi}' "
        f"AND parola_hash = crypt('{parola}', parola_hash)"
    )
    print("  Olusan SQL:\n    " + sorgu)
    with conn.cursor() as cur:
        cur.execute(sorgu)
        return cur.fetchall()


def guvenli_giris(conn, kullanici_adi, parola):
    """GUVENLI: Parametreli sorgu - girdi asla SQL kodu olarak yorumlanmaz."""
    sorgu = (
        "SELECT kullanici_adi, rol FROM kullanicilar "
        "WHERE kullanici_adi = %s "
        "AND parola_hash = crypt(%s, parola_hash)"
    )
    print("  Olusan SQL (parametreli):\n    " + sorgu + "   parametreler=(%r, %r)" % (kullanici_adi, parola))
    with conn.cursor() as cur:
        cur.execute(sorgu, (kullanici_adi, parola))
        return cur.fetchall()


def dene(conn, fonk, baslik, kullanici_adi, parola):
    print(f"\n>>> {baslik}")
    print(f"    Girilen kullanici adi : {kullanici_adi!r}")
    print(f"    Girilen parola        : {parola!r}")
    try:
        sonuc = fonk(conn, kullanici_adi, parola)
    except Exception as e:
        conn.rollback()
        print(f"    SONUC: Hata/engellendi -> {e}")
        return
    conn.rollback()
    if sonuc:
        print(f"    SONUC: GIRIS BASARILI -> {sonuc}")
    else:
        print(f"    SONUC: Giris reddedildi (bos sonuc)")


def main():
    try:
        conn = psycopg2.connect(**BAGLANTI)
    except Exception as e:
        print("Veritabanina baglanilamadi:", e)
        print("PGPASSWORD ortam degiskenini ayarladiniz mi? Or: $env:PGPASSWORD='Banka2025'")
        sys.exit(1)

    print(CIZGI)
    print("SQL INJECTION DEMOSU - guvenlik_db.kullanicilar")
    print(CIZGI)

    # Saldiri girdisi: kullanici adi alanina  admin'--  yazip parola kontrolunu yorum satirina aliyoruz
    saldiri_kadi = "admin' --"
    saldiri_parola = "herhangi_birsey"

    print("\n" + CIZGI)
    print("1) ZAFIYETLI YONTEM (string birlestirme)")
    print(CIZGI)
    dene(conn, acik_giris, "Normal dogru giris (admin / Admin*2025)", "admin", "Admin*2025")
    dene(conn, acik_giris, "Yanlis parola ile giris", "admin", "yanlis")
    dene(conn, acik_giris, "SQL ENJEKSIYON SALDIRISI (parola bilmeden!)", saldiri_kadi, saldiri_parola)

    print("\n" + CIZGI)
    print("2) GUVENLI YONTEM (parametreli sorgu)")
    print(CIZGI)
    dene(conn, guvenli_giris, "Normal dogru giris (admin / Admin*2025)", "admin", "Admin*2025")
    dene(conn, guvenli_giris, "AYNI ENJEKSIYON SALDIRISI (artik engellenir)", saldiri_kadi, saldiri_parola)

    print("\n" + CIZGI)
    print("SONUC: Zafiyetli yontemde saldirgan parolayi bilmeden 'admin' olarak giris")
    print("yapabildi. Parametreli sorguda ayni saldiri ETKISIZ kaldi (giris reddedildi).")
    print("KORUNMA: Her zaman parametreli sorgu / prepared statement kullanin.")
    print(CIZGI)
    conn.close()


if __name__ == "__main__":
    main()
