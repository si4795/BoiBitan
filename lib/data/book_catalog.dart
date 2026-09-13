import '../models/book.dart';

class BookCatalog {
  static const List<String> categories = [
    'category_all',
    'category_bangla_novel',
    'category_translated',
    'category_islamic_selfhelp',
    'category_scifi',
    'category_english_classics',
  ];

  static final List<Book> books = [
    // 1. Shesher Kobita - Rabindranath Tagore
    const Book(
      id: 'shesher_kobita',
      title: 'Shesher Kobita',
      titleBn: 'শেষের কবিতা',
      author: 'Rabindranath Tagore',
      authorBn: 'রবীন্দ্রনাথ ঠাকুর',
      category: 'Bengali Novels',
      categoryBn: 'বাংলা উপন্যাস',
      description: 'Shesher Kobita is a timeless romantic tragedy of intellectual love and emotional detachment between Amit Ray and Labanya, set in the serene misty hills of Shillong.',
      descriptionBn: 'অমিত রায় ও লাবণ্যের জটিল মনস্তাত্ত্বিক প্রেম, বিচ্ছেদ এবং প্লেটোনিক অনুভূতির এক অনন্য কাব্যিক আখ্যান। শিলংয়ের শান্ত পাহাড়ি প্রেক্ষাপটে রচিত রবীন্দ্রনাথ ঠাকুরের অমর উপন্যাস।',
      coverUrl: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?auto=format&fit=crop&w=600&q=80',
      rating: 4.9,
      reviewCount: 1420,
      pageCount: 184,
      fileSize: '7.4 MB',
      publicationYear: 1929,
      downloadUrl: 'https://ia601906.us.archive.org/32/items/in.ernet.dli.2015.456108/2015.456108.Shesher-Kabita.pdf',
      assetPdfPath: 'assets/sample_book.pdf',
      isFeatured: true,
      isTrending: true,
    ),

    // 2. Devdas - Sarat Chandra Chattopadhyay
    const Book(
      id: 'devdas',
      title: 'Devdas',
      titleBn: 'দেবদাস',
      author: 'Sarat Chandra Chattopadhyay',
      authorBn: 'শরৎচন্দ্র চট্টোপাধ্যায়',
      category: 'Bengali Novels',
      categoryBn: 'বাংলা উপন্যাস',
      description: 'The iconic tragic tale of unrequited love, pride, and self-destruction revolving around Devdas, Parvati (Paro), and Chandramukhi.',
      descriptionBn: 'অভিমান, সমাজ ও বিরহের করুণ বিয়োগান্তক রূপকার দেবদাস। পার্বতীর প্রতি গভীর প্রেম ও আত্মবিধ্বংসী পথ বেছে নেওয়া এক চিরন্তন ট্র্যাজেডি।',
      coverUrl: 'https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=600&q=80',
      rating: 4.8,
      reviewCount: 2310,
      pageCount: 140,
      fileSize: '441 KB',
      publicationYear: 1917,
      downloadUrl: 'https://ia800601.us.archive.org/7/items/devdas_303/Sharatchandra-Devdas.pdf',
      assetPdfPath: 'assets/sample_book.pdf',
      isFeatured: true,
      isTrending: true,
    ),

    // 3. Misir Ali: Ami Ebong Amra - Humayun Ahmed
    const Book(
      id: 'misir_ali_ami_ebong_amra',
      title: 'Misir Ali: Ami Ebong Amra',
      titleBn: 'আমি এবং আমরা (মিসির আলি)',
      author: 'Humayun Ahmed',
      authorBn: 'হুমায়ূন আহমেদ',
      category: 'Bengali Novels',
      categoryBn: 'বাংলা উপন্যাস',
      description: 'Part-time psychology professor Misir Ali unravels perplexing paranormal mysteries purely with cold logic, keen observation, and human psychology.',
      descriptionBn: 'যুক্তিবাদী ও আপাত নির্লিপ্ত মিসির আলির রহস্য সমাধান। অতিপ্রাকৃতিক ও অদ্ভুত ঘটনার পেছনে মানুষের অবচেতন মনের গোপন খেলার বৈজ্ঞানিক অনুসন্ধান।',
      coverUrl: 'https://images.unsplash.com/photo-1507842229451-7f01be837a27?auto=format&fit=crop&w=600&q=80',
      rating: 4.9,
      reviewCount: 3105,
      pageCount: 72,
      fileSize: '846 KB',
      publicationYear: 1993,
      downloadUrl: 'https://ia800605.us.archive.org/23/items/SahajPath-Part1-Bangla/bangla-sahaj-paath1.pdf',
      assetPdfPath: 'assets/sample_book.pdf',
      isFeatured: true,
      isTrending: true,
    ),

    // 4. Srikanta - Sarat Chandra Chattopadhyay
    const Book(
      id: 'srikanta',
      title: 'Srikanta',
      titleBn: 'শ্রীকান্ত',
      author: 'Sarat Chandra Chattopadhyay',
      authorBn: 'শরৎচন্দ্র চট্টোপাধ্যায়',
      category: 'Bengali Novels',
      categoryBn: 'বাংলা উপন্যাস',
      description: 'A sprawling autobiographical picaresque novel following wandering wanderer Srikanta and the unforgettable, self-sacrificing Rajlakshmi.',
      descriptionBn: 'এক ভবঘুরে যুবকের চোখে উন্মোচিত তৎকালীন বঙ্গসমাজ ও নারী হৃদয়ের গভীর অনুভূতির চার খণ্ডের মহাকাব্যিক আত্মজৈবনিক উপন্যাস।',
      coverUrl: 'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?auto=format&fit=crop&w=600&q=80',
      rating: 4.7,
      reviewCount: 980,
      pageCount: 240,
      fileSize: '5.8 MB',
      publicationYear: 1917,
      downloadUrl: 'https://archive.org/download/in.ernet.dli.2015.340033/2015.340033.1331-32-B.pdf',
      assetPdfPath: 'assets/sample_book.pdf',
      isFeatured: false,
      isTrending: true,
    ),

    // 5. Shankhonil Karagar - Humayun Ahmed
    const Book(
      id: 'shankhonil_karagar',
      title: 'Shankhonil Karagar',
      titleBn: 'শঙ্খনীল কারাগার',
      author: 'Humayun Ahmed',
      authorBn: 'হুমায়ূন আহমেদ',
      category: 'Bengali Novels',
      categoryBn: 'বাংলা উপন্যাস',
      description: 'A moving chronicle of a lower middle-class Dhaka family bound by quiet affections, hidden sacrifices, and sudden unspoken sorrows.',
      descriptionBn: 'মধ্যবিত্ত জীবনের পাওয়া না-পাওয়ার টানাপোড়েন, মৃদু আনন্দ ও অতল বেদনার অপূর্ব রূপায়ণ। হুমায়ূন আহমেদের প্রথম দিককার অবিস্মরণীয় সৃষ্টি।',
      coverUrl: 'https://images.unsplash.com/photo-1543002588-bfa74002ed7e?auto=format&fit=crop&w=600&q=80',
      rating: 4.9,
      reviewCount: 4200,
      pageCount: 96,
      fileSize: '1.7 MB',
      publicationYear: 1973,
      downloadUrl: 'https://ia600808.us.archive.org/16/items/SahajPath-Part2-Bangla/bangla-sahaj-paath2.pdf',
      assetPdfPath: 'assets/sample_book.pdf',
      isFeatured: true,
      isTrending: true,
    ),

    // 6. Anandamath - Bankim Chandra Chattopadhyay
    const Book(
      id: 'anandamath',
      title: 'Anandamath',
      titleBn: 'আনন্দমঠ',
      author: 'Bankim Chandra Chattopadhyay',
      authorBn: 'বঙ্কিমচন্দ্র চট্টোপাধ্যায়',
      category: 'Bengali Novels',
      categoryBn: 'বাংলা উপন্যাস',
      description: 'Historical political fiction set during the Bengal Famine of 1770 and the Sannyasi rebellion, originating the anthem Vande Mataram.',
      descriptionBn: '১৭৭০ সালের ছিয়াত্তরের মন্বন্তর ও সন্ন্যাসী বিদ্রোহের প্রেক্ষাপটে রচিত ঐতিহাসিক দেশাত্মবোধক উপন্যাস, যার মাধ্যমে ‘বন্দে মাতরম’ গানের জন্ম।',
      coverUrl: 'https://images.unsplash.com/photo-1463320726281-696a485928c7?auto=format&fit=crop&w=600&q=80',
      rating: 4.6,
      reviewCount: 750,
      pageCount: 210,
      fileSize: '6.5 MB',
      publicationYear: 1882,
      downloadUrl: 'https://archive.org/download/AnadamathTheAbbeyOfBlissChatterjee02/Anadamath%20-%20The%20Abbey%20of%20Bliss%20-%20Chatterjee%20trans%20Sen-Gupta%20%28cleaned%29.pdf',
      assetPdfPath: 'assets/sample_book.pdf',
      isFeatured: false,
      isTrending: false,
    ),

    // 7. The Alchemist - Paulo Coelho (অনূদিত)
    const Book(
      id: 'the_alchemist',
      title: 'The Alchemist',
      titleBn: 'দ্য আলকেমিস্ট',
      author: 'Paulo Coelho',
      authorBn: 'পাওলো কোয়েলহো',
      category: 'Translated Literature',
      categoryBn: 'অনূদিত সাহিত্য',
      description: 'An inspiring philosophical journey of Santiago, an Andalusian shepherd boy, who yearns to travel in search of a worldly treasure.',
      descriptionBn: 'নিজের স্বপ্ন ও ভাগ্যের অনুসন্ধানে এক রাখাল বালকের মরুপথে রূপক যাত্রা। অন্তরের কথা শোনা এবং ব্যক্তিগত নিয়তি আবিষ্কারের জাদুকরি অনুপ্রেরণা।',
      coverUrl: 'https://images.unsplash.com/photo-1532012164546-f432f2e3edd4?auto=format&fit=crop&w=600&q=80',
      rating: 4.8,
      reviewCount: 5120,
      pageCount: 172,
      fileSize: '505 KB',
      publicationYear: 1988,
      downloadUrl: 'https://ia803209.us.archive.org/11/items/PauloCoelhoTheAlchemist/_Paulo_Coelho__The_Alchemist).pdf',
      assetPdfPath: 'assets/sample_book.pdf',
      isFeatured: true,
      isTrending: true,
    ),

    // 8. The Old Man and the Sea - Ernest Hemingway (অনূদিত)
    const Book(
      id: 'old_man_sea',
      title: 'The Old Man and the Sea',
      titleBn: 'দ্য ওল্ড ম্যান অ্যান্ড দ্য সি',
      author: 'Ernest Hemingway',
      authorBn: 'আর্নেস্ট হেমিংওয়ে',
      category: 'Translated Literature',
      categoryBn: 'অনূদিত সাহিত্য',
      description: 'A heroic, gritty struggle between an aging Cuban fisherman and the greatest catch of his life far out in the Gulf Stream.',
      descriptionBn: 'এক প্রবীণ কিউবান জেলের সঙ্গে সুবিশাল মার্লিন মাছের অদম্য লড়াই। মানুষের পরাজয় না মানার চরম সাহসিকতার অমর আখ্যান। নোবেলজয়ী ক্লাসিক।',
      coverUrl: 'https://images.unsplash.com/photo-1518495973542-4542c06a5843?auto=format&fit=crop&w=600&q=80',
      rating: 4.7,
      reviewCount: 3890,
      pageCount: 128,
      fileSize: '4.6 MB',
      publicationYear: 1952,
      downloadUrl: 'https://ia803109.us.archive.org/21/items/the_old_man_and_the_sea/Lelaki%20Tua%20dan%20Laut%20%28The%20Old%20Man%20and%20the%20Sea%29%20-%20Ernest%20Hemingway.pdf',
      assetPdfPath: 'assets/sample_book.pdf',
      isFeatured: false,
      isTrending: true,
    ),

    // 9. Sherlock Holmes: Selected Cases - Arthur Conan Doyle (অনূদিত)
    const Book(
      id: 'sherlock_holmes',
      title: 'The Adventures of Sherlock Holmes',
      titleBn: 'শার্লক হোমস সমগ্র: সেরা রহস্য',
      author: 'Arthur Conan Doyle',
      authorBn: 'স্যার আর্থার কোনান ডয়েল',
      category: 'Translated Literature',
      categoryBn: 'অনূদিত সাহিত্য',
      description: 'The master consulting detective Sherlock Holmes and Dr. John Watson tackle bizarre puzzles and criminal intrigues across Victorian London.',
      descriptionBn: 'লন্ডনের ২২১বি বেকার স্ট্রিটের রহস্যসন্ধানী শার্লক হোমস ও ডক্টর ওয়াটসনের শ্বাসরুদ্ধকর বুদ্ধিমত্তা ও নিখুঁত পর্যবেক্ষণ শক্তির অনন্য তদন্ত কাহিনী।',
      coverUrl: 'https://images.unsplash.com/photo-1541963463532-d68292c34b19?auto=format&fit=crop&w=600&q=80',
      rating: 4.9,
      reviewCount: 4670,
      pageCount: 312,
      fileSize: '18.3 MB',
      publicationYear: 1892,
      downloadUrl: 'https://archive.org/download/adventuresofsher00doyl/adventuresofsher00doyl.pdf',
      assetPdfPath: 'assets/sample_book.pdf',
      isFeatured: true,
      isTrending: true,
    ),

    // 10. Pride and Prejudice - Jane Austen
    const Book(
      id: 'pride_and_prejudice',
      title: 'Pride and Prejudice',
      titleBn: 'প্রাইড অ্যান্ড প্রেজুডিস',
      author: 'Jane Austen',
      authorBn: 'জেন অস্টেন',
      category: 'English Classics',
      categoryBn: 'ইংরেজি ক্লাসিকস',
      description: 'A witty romantic masterpiece charting the turbulent relationship between Elizabeth Bennet and the proud aristocrat Fitzwilliam Darcy.',
      descriptionBn: 'বুদ্ধিমতী এলিজাবেথ বেনেট ও অহংকারী মি. ডার্সির সামাজিক দ্বন্দ্ব ও প্রেমের সূক্ষ্ম রসায়নে রচিত ইংরেজি সাহিত্যের কালজয়ী রোমান্টিক উপন্যাস।',
      coverUrl: 'https://images.unsplash.com/photo-1476275466078-4007374efbbe?auto=format&fit=crop&w=600&q=80',
      rating: 4.8,
      reviewCount: 6540,
      pageCount: 360,
      fileSize: '8.2 MB',
      publicationYear: 1813,
      downloadUrl: 'https://ia803106.us.archive.org/25/items/austen-pride-and-prejudice/Austen_Pride_and_Prejudice.pdf',
      assetPdfPath: 'assets/sample_book.pdf',
      isFeatured: true,
      isTrending: true,
    ),

    // 11. Alice in Wonderland - Lewis Carroll
    const Book(
      id: 'alice_in_wonderland',
      title: "Alice's Adventures in Wonderland",
      titleBn: 'অ্যালিসেস অ্যাডভেঞ্চারস ইন ওয়ান্ডারল্যান্ড',
      author: 'Lewis Carroll',
      authorBn: 'লুইস ক্যারল',
      category: 'English Classics',
      categoryBn: 'ইংরেজি ক্লাসিকস',
      description: 'A young girl falls down a rabbit hole into a subterranean fantasy world populated by peculiar, anthropomorphic creatures.',
      descriptionBn: 'খরগোশের গর্ত বেয়ে এক অদ্ভুত কাল্পনিক জগতে প্রবেশ করা ছোট্ট অ্যালিসের বিস্ময়কর রূপকথা ও প্রতীকী সাহিত্য সৃষ্টি।',
      coverUrl: 'https://images.unsplash.com/photo-1495640388908-05fa85288e61?auto=format&fit=crop&w=600&q=80',
      rating: 4.7,
      reviewCount: 3410,
      pageCount: 152,
      fileSize: '2.2 MB',
      publicationYear: 1865,
      downloadUrl: 'https://ia801901.us.archive.org/24/items/AlicesAdventuresInWonderland/alice-in-wonderland.pdf',
      assetPdfPath: 'assets/sample_book.pdf',
      isFeatured: false,
      isTrending: true,
    ),

    // 12. Gitanjali (Song Offerings) - Rabindranath Tagore
    const Book(
      id: 'gitanjali',
      title: 'Gitanjali',
      titleBn: 'গীতাঞ্জলি',
      author: 'Rabindranath Tagore',
      authorBn: 'রবীন্দ্রনাথ ঠাকুর',
      category: 'Poetry & Drama',
      categoryBn: 'কবিতা ও নাটক',
      description: 'A spiritual collection of devotional poetry celebrating divine presence, nature, and the human soul, which won the Nobel Prize in Literature in 1913.',
      descriptionBn: '১৯১৩ সালে সাহিত্যে নোবেলজয়ী রবীন্দ্রনাথ ঠাকুরের ভক্তিমূলক ও দার্শনিক কাব্যসংগ্রহ। মানবাত্মা ও বিশ্ববিধাতার শাশ্বত মিলনের স্বর্গীয় সঙ্গীত।',
      coverUrl: 'https://images.unsplash.com/photo-1457369804613-52c61a468e7d?auto=format&fit=crop&w=600&q=80',
      rating: 4.9,
      reviewCount: 3820,
      pageCount: 160,
      fileSize: '5.4 MB',
      publicationYear: 1910,
      downloadUrl: 'https://ia803206.us.archive.org/25/items/gitanjalisongoff00tagouoft/gitanjalisongoff00tagouoft.pdf',
      assetPdfPath: 'assets/sample_book.pdf',
      isFeatured: true,
      isTrending: false,
    ),

    // 13. Deepu Number Two - Muhammed Zafar Iqbal
    const Book(
      id: 'deepu_number_two',
      title: 'Deepu Number Two',
      titleBn: 'দীপু নাম্বার টু',
      author: 'Muhammed Zafar Iqbal',
      authorBn: 'মুহাম্মদ জাফর ইকবাল',
      category: 'Bengali Novels',
      categoryBn: 'বাংলা উপন্যাস',
      description: 'A gripping adolescent coming-of-age story following brave young Deepu as he navigates boarding school, friendship, and an ancient smuggling plot.',
      descriptionBn: 'কৈশোরের বন্ধুত্ব, স্কুলজীবন ও এক প্রাচীন মূর্তি চোরচক্রের বিরুদ্ধে সাহসী দীপ ও তার বন্ধুদের রোমাঞ্চকর অভিযানের গল্প।',
      coverUrl: 'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?auto=format&fit=crop&w=600&q=80',
      rating: 4.8,
      reviewCount: 2900,
      pageCount: 88,
      fileSize: '846 KB',
      publicationYear: 1984,
      downloadUrl: 'https://ia800605.us.archive.org/23/items/SahajPath-Part1-Bangla/bangla-sahaj-paath1.pdf',
      assetPdfPath: 'assets/sample_book.pdf',
      isFeatured: false,
      isTrending: true,
    ),

    // 14. Atomic Habits (অনূদিত) - James Clear
    const Book(
      id: 'atomic_habits',
      title: 'Atomic Habits',
      titleBn: 'অ্যাটমিক হ্যাবিটস',
      author: 'James Clear',
      authorBn: 'জেমস ক্লিয়ার',
      category: 'Self-Help & Career',
      categoryBn: 'মোটিভেশন ও ক্যারিয়ার',
      description: 'An easy and proven way to build good habits and break bad ones using the compounding power of tiny 1% everyday improvements.',
      descriptionBn: 'দৈনন্দিন ছোট্ট ১% ইতিবাচক পরিবর্তনের মাধ্যমে কীভাবে জীবনের দীর্ঘমেয়াদী অসাধারণ সাফল্য অর্জন করা যায় তার বিজ্ঞানসম্মত ও ব্যবহারিক নির্দেশিকা।',
      coverUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=600&q=80',
      rating: 4.9,
      reviewCount: 7800,
      pageCount: 208,
      fileSize: '1.5 MB',
      publicationYear: 2018,
      downloadUrl: 'https://ia800408.us.archive.org/2/items/10TheAlchemist25thAnniversaryEditionPauloCoelho/10%20The%20Alchemist%20%2825th%20Anniversary%20Edition%29%20-%20Paulo%20Coelho.pdf',
      assetPdfPath: 'assets/sample_book.pdf',
      isFeatured: true,
      isTrending: true,
    ),

    // 12. Paradoxical Sajid - Arif Azad
    const Book(
      id: 'paradoxical_sajid',
      title: 'Paradoxical Sajid',
      titleBn: 'প্যারাডক্সিক্যাল সাজিদ',
      author: 'Arif Azad',
      authorBn: 'আরিফ আজাদ',
      category: 'Islamic & Self-Help',
      categoryBn: 'ইসলামিক ও আত্মউন্নয়ন',
      description: 'A bestselling contemporary collection of logical, scientific, and theological dialogues defending Islamic faith through reason, philosophy, and engaging storytelling.',
      descriptionBn: 'যুক্তি, বিজ্ঞান এবং দর্শনের সমন্বয়ে ইসলামি বিশ্বাসের যৌক্তিক উপস্থাপনা। সমকালীন তরুণ প্রজন্মের মধ্যে সর্বাধিক পঠিত ও আলোচিত বই।',
      coverUrl: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?auto=format&fit=crop&w=600&q=80',
      rating: 4.95,
      reviewCount: 9240,
      pageCount: 224,
      fileSize: '8.4 MB',
      publicationYear: 2017,
      downloadUrl: 'https://archive.org/download/ParadoxicalSajid/Paradoxical%20Sajid.pdf',
      previewUrl: 'https://archive.org/details/ParadoxicalSajid',
      assetPdfPath: 'assets/sample_book.pdf',
      isFeatured: true,
      isTrending: true,
    ),

    // 13. Ahok - Humayun Ahmed
    const Book(
      id: 'ahok_humayun_ahmed',
      title: 'Ahok',
      titleBn: 'অঁহক',
      author: 'Humayun Ahmed',
      authorBn: 'হুমায়ূন আহমেদ',
      category: 'Science & Sci-Fi',
      categoryBn: 'বিজ্ঞান ও ফিকশন',
      description: 'A fascinating science fiction novel by Humayun Ahmed exploring extraterrestrial intelligence, space mystery, and human connection.',
      descriptionBn: 'হুমায়ূন আহমেদের রোমাঞ্চকর বিজ্ঞান কল্পকাহিনী যেখানে মহাজাগতিক রহস্য, গ্রহান্তর যাত্রা ও মানব অনুভূতির গভীর গল্প ফুটে উঠেছে।',
      coverUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=600&q=80',
      rating: 4.85,
      reviewCount: 3100,
      pageCount: 160,
      fileSize: '5.2 MB',
      publicationYear: 1993,
      downloadUrl: 'https://archive.org/download/AhokByHumayunAhmedScienceFiction/Ahok%20by%20Humayun%20Ahmed%5BScience%20Fiction%5D.pdf',
      previewUrl:
          'https://archive.org/details/AhokByHumayunAhmedScienceFiction',
      assetPdfPath: 'assets/sample_book.pdf',
      isFeatured: true,
      isTrending: true,
    ),

    // 14. The War of the Worlds - H. G. Wells
    const Book(
      id: 'war_of_the_worlds',
      title: 'The War of the Worlds',
      titleBn: 'দ্য ওয়ার অব দ্য ওয়ার্ল্ডস',
      author: 'H. G. Wells',
      authorBn: 'এইচ. জি. ওয়েলস',
      category: 'Science & Sci-Fi',
      categoryBn: 'বিজ্ঞান ও ফিকশন',
      description: 'The definitive pioneer of alien invasion science fiction, capturing humanity’s desperate struggle against ruthless Martian tripods.',
      descriptionBn: 'ভিনগ্রহের প্রাণীদের পৃথিবী আক্রমণের প্রথম ও কালজয়ী বৈজ্ঞানিক কল্পকাহিনী। মঙ্গলগ্রহের দানবীয় ট্রাইপডের বিরুদ্ধে মানবজাতির বেঁচে থাকার মহাকাব্যিক লড়াই।',
      coverUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=600&q=80',
      rating: 4.9,
      reviewCount: 4780,
      pageCount: 304,
      fileSize: '10.4 MB',
      publicationYear: 1898,
      downloadUrl: 'https://archive.org/download/warofworlds00welluoft/warofworlds00welluoft.pdf',
      previewUrl: 'https://archive.org/details/warofworlds00welluoft',
      assetPdfPath: 'assets/sample_book.pdf',
      isFeatured: true,
      isTrending: true,
    ),
  ];

  static Book? getById(String id) {
    try {
      return books.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<Book> getFeatured() => books.where((b) => b.isFeatured).toList();
  static List<Book> getTrending() => books.where((b) => b.isTrending).toList();
  static List<Book> getBengaliClassics() =>
      books.where((b) => b.category == 'Bengali Novels').toList();
  static List<Book> getTranslated() =>
      books.where((b) => b.category == 'Translated Literature').toList();
  static List<Book> getEnglishClassics() =>
      books.where((b) => b.category == 'English Classics').toList();
  static List<Book> getIslamicAndSelfHelp() =>
      books.where((b) => b.category == 'Islamic & Self-Help').toList();
  static List<Book> getSciFi() =>
      books.where((b) => b.category == 'Science & Sci-Fi').toList();

  static List<Book> search(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return books;
    return books.where((b) {
      return b.title.toLowerCase().contains(clean) ||
          b.titleBn.toLowerCase().contains(clean) ||
          b.author.toLowerCase().contains(clean) ||
          b.authorBn.toLowerCase().contains(clean) ||
          b.category.toLowerCase().contains(clean) ||
          b.categoryBn.toLowerCase().contains(clean);
    }).toList();
  }
}
