const baseTemplate =
  'Görev: Photo B\'deki kişinin (hedef kişi) Photo A\'daki {category} ürününü giydiği fotogerçekçi bir kompozit oluştur.\n\nKimlik Kilidi ve Vücut Bütünlüğü:\n- Photo B\'deki kişinin yüzünü aynen koru: yüz geometrisi, cilt dokusu, ben/yara izleri, saç çizgisi, kaşlar, göz rengi, dişler veya ifade üzerinde hiçbir değişiklik yapma.\n- Yüzü inceltme, güzelleştirme, pürüzsüzleştirme, retouch uygulama. Orijinal baş yönünü ve Photo B\'deki kamera perspektifini koru.\n- Tüm vücut oranlarını ve pozunu koru. Vücut şekli, boy, ağırlık, kol/el pozisyonları veya duruş değişmesin.\n- Elleri kesme veya pozu değiştirme. Yaş, cinsiyet, saç stili, makyaj, ten rengi, ifade, vücut şekli veya lens perspektifini değiştirme.\n\nÜrün Aktarımı ve Birebir Eşleşme:\n- Photo B\'deki üst vücut giyimini Photo A\'daki {category} ile değiştir.\n- Kumaşın dokusunu, rengini (tam ton ve doygunluk), desenini, parlaklığını, düğme/fermuar detaylarını, yaka/rever şeklini, dikiş izlerini ve logo yerleşimini Photo A ile birebir eşleştir.\n- {category} ürününü kişinin mevcut pozuna göre doğal şekilde gövdeye ve kollara oturt; gerçekçi katlanma/kırışıklıklar oluştur, vücut veya ellerle çakışma (clipping) olmasın.\n- Ürünün üzerindeki tüm detaylar (cepler, yamalar, etiketler, süslemeler) eksiksiz ve bozulmamış aktarılmalı.\n- Ürünün boyutunu Photo B\'deki kişiye uyacak şekilde ayarla fakat Photo A\'daki ürünün kesimini, kalıbını ve oranlarını koru.\n- Sarkma veya gerilme, Photo A\'daki kumaşın doğal davranışını yansıtmalı.\n\nArka Plan ve Aydınlatma:\n- Arka planı nötr, dikişsiz gri/beyaz stüdyo arka planına çevir ve yumuşak, gerçekçi gölgeler ekle.\n- Aydınlatmayı Photo B ile tutarlı tut: ana ışık yönü ve yoğunluğunu eşleştir, böylece giysi ve yüz birlikte yakalanmış gibi görünsün.\n\nÇıktı Görünümü:\n- Yüksek çözünürlüklü, temiz ve keskin; fotogerçekçi renk ve doku; resimsi veya çizgi film efektleri kullanma.\n- Ürün sunumu için hazır olmalı.\n\nTeslim Edilebilir:\n- Photo B\'deki kişinin Photo A\'daki {category} ürününü giydiği, nötr stüdyo arka planında, ürün sunumu için hazır tam vücut görüntü oluştur.';

function buildPrompt(category) {
  const safeCategory = category?.toString().trim() ?? 'garment';
  return baseTemplate.split('{category}').join(safeCategory);
}

function getPrompt(req, res) {
  const category = req.query.category?.toString().trim() || 'garment';
  res.json({
    category,
    prompt: buildPrompt(category),
  });
}

module.exports = {
  getPrompt,
  buildPrompt,
};
