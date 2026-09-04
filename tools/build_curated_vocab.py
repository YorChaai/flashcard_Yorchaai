# -*- coding: utf-8 -*-
"""
Kamus kurasi kontekstual untuk kata-kata umum dan ambigu (Homonim / Polisemi).
Menyelaraskan Kata Inggris + Arti Indonesia + Kelas Kata -> Bahasa Jepang Alami.
"""

import json
import os

curated_map = {
    # Ambiguous Nouns & Polysemous Words
    "watch": {"kanji": "腕時計", "hiragana": "うでどけい", "katakana": "ウォッチ", "romaji": "udedokei"},
    "bank": {"kanji": "銀行", "hiragana": "ぎんこう", "katakana": "バンク", "romaji": "ginkō"},
    "novel": {"kanji": "小説", "hiragana": "しょうせつ", "katakana": "ノベル", "romaji": "shōsetsu"},
    "spell": {"kanji": "綴る", "hiragana": "つづる", "katakana": "スペル", "romaji": "tsudzuru"},
    "tragedy": {"kanji": "悲劇", "hiragana": "ひげき", "katakana": "—", "romaji": "higeki"},
    "drama": {"kanji": "—", "hiragana": "どらま", "katakana": "ドラマ", "romaji": "dorama"},
    "comedy": {"kanji": "喜劇", "hiragana": "きげき", "katakana": "コメディ", "romaji": "kigeki"},
    "play": {"kanji": "遊ぶ", "hiragana": "あそぶ", "katakana": "プレイ", "romaji": "asobu"},
    "run": {"kanji": "走る", "hiragana": "はしる", "katakana": "ラン", "romaji": "hashiru"},
    "know": {"kanji": "知る", "hiragana": "しる", "katakana": "—", "romaji": "shiru"},
    "send": {"kanji": "送る", "hiragana": "おくる", "katakana": "—", "romaji": "okuru"},
    "fall": {"kanji": "落ちる", "hiragana": "おちる", "katakana": "フォール", "romaji": "ochiru"},
    "mean": {"kanji": "意味する", "hiragana": "いみする", "katakana": "—", "romaji": "imi suru"},
    "mine": {"kanji": "私のもの", "hiragana": "わたしのもの", "katakana": "マイン", "romaji": "watashi no mono"},
    "fair": {"kanji": "公平", "hiragana": "こうへい", "katakana": "フェア", "romaji": "kōhei"},
    "match": {"kanji": "合う", "hiragana": "あう", "katakana": "マッチ", "romaji": "au"},
    "park": {"kanji": "公園", "hiragana": "こうえん", "katakana": "パーク", "romaji": "kōen"},
    "light": {"kanji": "光", "hiragana": "ひかり", "katakana": "ライト", "romaji": "hikari"},
    "sound": {"kanji": "音", "hiragana": "おと", "katakana": "サウンド", "romaji": "oto"},
    "rock": {"kanji": "岩", "hiragana": "いわ", "katakana": "ロック", "romaji": "iwa"},
    "spring": {"kanji": "春", "hiragana": "はる", "katakana": "スプリング", "romaji": "haru"},
    "fly": {"kanji": "飛ぶ", "hiragana": "とぶ", "katakana": "フライ", "romaji": "tobu"},
    "wave": {"kanji": "波", "hiragana": "なみ", "katakana": "ウェーブ", "romaji": "nami"},
    "tie": {"kanji": "結ぶ", "hiragana": "むすぶ", "katakana": "タイ", "romaji": "musubu"},
    "tire": {"kanji": "—", "hiragana": "たいや", "katakana": "タイヤ", "romaji": "taiya"},
    "nail": {"kanji": "釘", "hiragana": "くぎ", "katakana": "ネイル", "romaji": "kugi"},
    "sink": {"kanji": "沈む", "hiragana": "しずむ", "katakana": "シンク", "romaji": "shizumu"},
    "ruler": {"kanji": "定規", "hiragana": "じょうぎ", "katakana": "ルーラー", "romaji": "jōgi"},
    "phone": {"kanji": "電話", "hiragana": "でんわ", "katakana": "フォン", "romaji": "denwa"},
    "much": {"kanji": "多い", "hiragana": "おおい", "katakana": "—", "romaji": "ōi"},
    "sports": {"kanji": "運動", "hiragana": "うんどう", "katakana": "スポーツ", "romaji": "supōtsu"},
    "hotel": {"kanji": "—", "hiragana": "ほてる", "katakana": "ホテル", "romaji": "hoteru"},
    "internet": {"kanji": "—", "hiragana": "いんたーねっと", "katakana": "インターネット", "romaji": "intānetto"},
    "computer": {"kanji": "電子計算機", "hiragana": "でんしけいさんき", "katakana": "コンピューター", "romaji": "konpyūtā"},
    "privacy": {"kanji": "個人情報", "hiragana": "こじんじょうほう", "katakana": "プライバシー", "romaji": "puraibashī"},
    "rights": {"kanji": "権利", "hiragana": "けんり", "katakana": "ライツ", "romaji": "kenri"},
    "forum": {"kanji": "掲示板", "hiragana": "けいじばん", "katakana": "フォーラム", "romaji": "keijiban"},
    "version": {"kanji": "版", "hiragana": "はん", "katakana": "バージョン", "romaji": "bān"},
    "photo": {"kanji": "写真", "hiragana": "しゃしん", "katakana": "フォト", "romaji": "shashin"},
    "network": {"kanji": "網", "hiragana": "あみ", "katakana": "ネットワーク", "romaji": "nettowāku"},
    "system": {"kanji": "制度", "hiragana": "せいど", "katakana": "システム", "romaji": "shisutemu"},
    "systems": {"kanji": "制度", "hiragana": "せいど", "katakana": "システム", "romaji": "shisutemu"},
    "books": {"kanji": "本", "hiragana": "ほん", "katakana": "ブック", "romaji": "hon"},
    "book": {"kanji": "本", "hiragana": "ほん", "katakana": "ブック", "romaji": "hon"},
    "read": {"kanji": "読む", "hiragana": "よむ", "katakana": "リード", "romaji": "yomu"},
    "reading": {"kanji": "読書", "hiragana": "どくしょ", "katakana": "リーディング", "romaji": "dokusho"},
    "write": {"kanji": "書く", "hiragana": "かく", "katakana": "ライト", "romaji": "kaku"},
    "walk": {"kanji": "歩く", "hiragana": "あるく", "katakana": "ウォーク", "romaji": "aruku"},
    "speak": {"kanji": "話す", "hiragana": "はなす", "katakana": "スピーク", "romaji": "hanasu"},
    "listen": {"kanji": "聞く", "hiragana": "きく", "katakana": "リスン", "romaji": "kiku"},
    "hear": {"kanji": "聞こえる", "hiragana": "きこえる", "katakana": "ヒア", "romaji": "kikoeru"},
    "eat": {"kanji": "食べる", "hiragana": "たべる", "katakana": "イート", "romaji": "taberu"},
    "drink": {"kanji": "飲む", "hiragana": "のむ", "katakana": "ドリンク", "romaji": "nomu"},
    "sleep": {"kanji": "眠る", "hiragana": "ねむる", "katakana": "スリープ", "romaji": "nemuru"},
    "buy": {"kanji": "買う", "hiragana": "かう", "katakana": "バイ", "romaji": "kau"},
    "sell": {"kanji": "売る", "hiragana": "うる", "katakana": "セル", "romaji": "uru"},
    "give": {"kanji": "与える", "hiragana": "あたえる", "katakana": "ギブ", "romaji": "ataeru"},
    "take": {"kanji": "取る", "hiragana": "とる", "katakana": "テイク", "romaji": "toru"},
    "open": {"kanji": "開ける", "hiragana": "あける", "katakana": "オープン", "romaji": "akeru"},
    "close": {"kanji": "閉める", "hiragana": "しめる", "katakana": "クローズ", "romaji": "shimeru"},
    "start": {"kanji": "始める", "hiragana": "はじめる", "katakana": "スタート", "romaji": "hajimeru"},
    "stop": {"kanji": "止める", "hiragana": "とめる", "katakana": "ストップ", "romaji": "tomeru"},
    "think": {"kanji": "思う", "hiragana": "おもう", "katakana": "シンク", "romaji": "omou"},
    "feel": {"kanji": "感じる", "hiragana": "かんじる", "katakana": "フィール", "romaji": "kanjiru"},
    "live": {"kanji": "生きる", "hiragana": "いきる", "katakana": "ライブ", "romaji": "ikiru"},
    "die": {"kanji": "死ぬ", "hiragana": "しぬ", "katakana": "ダイ", "romaji": "shinu"},
    "stand": {"kanji": "立つ", "hiragana": "たつ", "katakana": "スタンド", "romaji": "tatsu"},
    "sit": {"kanji": "座る", "hiragana": "すわる", "katakana": "シット", "romaji": "suwaru"},
    "wait": {"kanji": "待つ", "hiragana": "まつ", "katakana": "ウェイト", "romaji": "matsu"},
    "hope": {"kanji": "望む", "hiragana": "のぞむ", "katakana": "ホープ", "romaji": "nozomu"},
    "love": {"kanji": "愛する", "hiragana": "あいする", "katakana": "ラブ", "romaji": "aisuru"},
    "like": {"kanji": "好き", "hiragana": "すき", "katakana": "ライク", "romaji": "suki"},
    "hate": {"kanji": "憎む", "hiragana": "にくむ", "katakana": "ヘイト", "romaji": "nikumu"},
}

out_path = r"d:\2. Organize\1. Projects\flashcard\tools\curated_core_vocabulary.json"
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(curated_map, f, ensure_ascii=False, indent=2)

print(f"Berhasil membuat {out_path} dengan {len(curated_map)} kata kurasi kontekstual!")
