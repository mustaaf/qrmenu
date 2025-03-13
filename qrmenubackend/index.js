const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const app = express();
const port = 3000;

// JWT Secret Key - Bu değeri güvenli bir ortam değişkeninden almanız önerilir
const JWT_SECRET = 'qrmenu-secret-key-should-be-complex';

app.use(cors());

// Uploads klasörünü statik dosya sunucusu olarak ekleyelim
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// İstek boyutu limitini artır (50MB) - Base64 kodlu görseller için
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

const pool = new Pool({
    user: 'postgres',
    host: 'localhost',
    database: 'restorandb',
    password: '1234',
    port: 5432,
});

// SQL sorgu loglama için orijinal query metodunu saklayalım
const originalQuery = pool.query;
pool.query = function(...args) {
    const sql = args[0];
    const params = args.length > 1 ? args[1] : [];

    console.log('\n📝 SQL SORGUSU:');
    console.log(sql);

    if (params && params.length > 0) {
        console.log('🔢 PARAMETRELER:', JSON.stringify(params));
    }

    return originalQuery.apply(this, args)
        .then(result => {
            console.log(`✅ SORGU BAŞARILI (${result.rowCount} satır etkilendi)`);
            return result;
        })
        .catch(err => {
            console.error('❌ SORGU HATASI:', err.message);
            throw err;
        });
};

// PostgreSQL bağlantı kontrolü
const checkDatabaseConnection = async() => {
    try {
        const client = await pool.connect();
        console.log('✅ PostgreSQL veritabanına başarıyla bağlandı');
        client.release();
        return true;
    } catch (error) {
        console.error('❌ PostgreSQL bağlantısı başarısız:', error.message);
        return false;
    }
};

// Uygulama başladığında bağlantıyı kontrol et
checkDatabaseConnection().then(isConnected => {
    if (!isConnected) {
        console.error('Veritabanı bağlantısı başarısız olduğu için uygulama sağlıklı çalışmayabilir!');
    }
});

app.use(express.json());

// İstek ve cevap loglama için response middleware
app.use((req, res, next) => {
    const originalJson = res.json;

    // Override res.json method to log responses
    res.json = function(data) {
        console.log('\n📤 CEVAP VERİLERİ:');
        console.log(JSON.stringify(data, null, 2));
        console.log('------------------------------');
        return originalJson.call(this, data);
    };

    next();
});

// Enhanced request logging middleware for detailed request information
app.use((req, res, next) => {
    const timestamp = new Date().toISOString();

    console.log('\n🔍 GELEN İSTEK DETAYLARI 🔍');
    console.log('⏰ Zaman:', timestamp);
    console.log('📋 Metod:', req.method);
    console.log('🌐 URL:', req.url);

    // Log route parameters
    if (Object.keys(req.params).length) {
        console.log('🔢 URL Parametreleri:');
        console.log(JSON.stringify(req.params, null, 2));
    }

    // Log query parameters
    if (Object.keys(req.query).length) {
        console.log('❓ Sorgu Parametreleri:');
        console.log(JSON.stringify(req.query, null, 2));
    }

    // Log request body for non-GET requests
    if (['POST', 'PUT', 'PATCH', 'DELETE'].includes(req.method) && req.body && Object.keys(req.body).length) {
        console.log('📦 İstek Gövdesi:');
        console.log(JSON.stringify(req.body, null, 2));
    }

    // Log headers (excluding authorization header details for security)
    const safeHeaders = {...req.headers };
    if (safeHeaders.authorization) {
        safeHeaders.authorization = safeHeaders.authorization.substring(0, 15) + '...';
    }

    console.log('🏷️ İstek Başlıkları:');
    console.log(JSON.stringify(safeHeaders, null, 2));

    console.log('🔵 İstek IP:', req.ip || req.connection.remoteAddress);
    console.log('📌 İstek Yolu:', req.path);
    console.log('------------------------------');

    next();
});

// Fixed helper function to convert relative image URLs to absolute URLs
const convertImageUrl = (imageUrl, req, restaurantId, categoryId) => {
    if (!imageUrl) return null;

    // If already a full URL, return as is
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        return imageUrl;
    }

    // Get hostname from request or use localhost
    const host = req.hostname || 'localhost';
    const protocol = req.protocol || 'http';

    // Clean up the image path to avoid duplication
    let processedImageUrl;
    const expectedPrefix = `uploads/${restaurantId}/${categoryId}/`;

    if (imageUrl.includes(expectedPrefix)) {
        // Path already has the correct structure, use it as is
        processedImageUrl = imageUrl;
    } else if (imageUrl.includes('/uploads/')) {
        // Path has some other uploads structure, extract the filename
        const parts = imageUrl.split('/');
        const fileName = parts[parts.length - 1];
        processedImageUrl = `${expectedPrefix}${fileName}`;
    } else {
        // Just a filename, add the full path
        const fileName = imageUrl.startsWith('/') ? imageUrl.slice(1) : imageUrl;
        processedImageUrl = `${expectedPrefix}${fileName}`;
    }

    // Make sure there's no duplicate leading slash
    const imagePath = processedImageUrl.startsWith('/') ? processedImageUrl.slice(1) : processedImageUrl;

    return `${protocol}://${host}:${port}/${imagePath}`;
};

// Ensure directory exists for uploads
const ensureDirectoryExists = (dirPath) => {
    if (!fs.existsSync(dirPath)) {
        fs.mkdirSync(dirPath, { recursive: true });
        console.log(`Dizin oluşturuldu: ${dirPath}`);
    }
};

// Enhanced helper function for base64 image handling with better logging and validation
const saveBase64Image = (base64String, restaurantId, categoryId, fileName) => {
    console.log('\n📸 GÖRSEL KAYIT İŞLEMİ BAŞLATILDI:');
    console.log(`Hedef klasör: uploads/${restaurantId}/${categoryId}/`);
    console.log(`Dosya adı: ${fileName}`);

    // Check if the string is a valid base64 image
    if (!base64String) {
        console.error('❌ Base64 görsel verisi eksik veya boş!');
        return null;
    }

    try {
        // Make sure we're parsing the base64 correctly
        let base64Data;
        if (base64String.includes(';base64,')) {
            // Format: data:image/jpeg;base64,/9j/4AAQ...
            base64Data = base64String.split(';base64,')[1];
            console.log('✅ Base64 veri formatı tanındı: data:image/...;base64,...');
        } else if (base64String.includes('base64,')) {
            // Format: base64,/9j/4AAQ...
            base64Data = base64String.split('base64,')[1];
            console.log('✅ Base64 veri formatı tanındı: base64,...');
        } else {
            // Assume it's already a raw base64 string
            base64Data = base64String;
            console.log('⚠️ Base64 veri formatı bilinmiyor, ham veri olarak kabul ediliyor');
        }

        // Check if we have valid data now
        if (!base64Data || base64Data.length < 100) {
            console.error(`❌ Base64 veri çok kısa veya geçersiz: ${base64Data?.substring(0, 20)}...`);
            return null;
        }

        // Create directory if it doesn't exist
        const dirPath = path.join(__dirname, 'uploads', restaurantId.toString(), categoryId.toString());
        ensureDirectoryExists(dirPath);

        // Create file path
        const filePath = path.join(dirPath, fileName);
        console.log(`📁 Dosya kaydediliyor: ${filePath}`);

        // Write the file
        fs.writeFileSync(filePath, base64Data, { encoding: 'base64' });
        console.log('✅ Dosya başarıyla kaydedildi!');

        // Return the relative path to be stored in the database
        const relativePath = `uploads/${restaurantId}/${categoryId}/${fileName}`;
        console.log(`🔗 Veritabanına kaydedilecek yol: ${relativePath}`);
        return relativePath;
    } catch (error) {
        console.error('❌ Resim kaydetme hatası:', error);
        return null;
    }
};

// Restoran kategorilerini getir
app.get('/restaurants/:restaurantId/categories', async(req, res) => {
    try {
        const { restaurantId } = req.params;
        const result = await pool.query('SELECT * FROM categories WHERE restaurant_id = $1', [restaurantId]);

        // Sorgu sonucunu log yapalım
        console.log(`\n📋 KATEGORİLER SORGUSU SONUCU: ${result.rows.length} kayıt bulundu`);

        // Image URLs'leri dönüştür
        const categories = result.rows.map(category => ({
            ...category,
            image_url: convertImageUrl(category.image_url, req, restaurantId, category.id)
        }));

        res.json(categories);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Belirli bir restoran ve kategoriye ait yemekleri getir
app.get('/restaurants/:restaurantId/categories/:categoryId/dishes', async(req, res) => {
    try {
        const { restaurantId, categoryId } = req.params;
        const result = await pool.query('SELECT * FROM dishes WHERE restaurant_id = $1 AND category_id = $2', [restaurantId, categoryId]);

        // Sorgu sonucunu log yapalım
        console.log(`\n🍽️ YEMEKLER SORGUSU SONUCU: ${result.rows.length} kayıt bulundu`);

        // Image URLs'leri dönüştür
        const dishes = result.rows.map(dish => ({
            ...dish,
            image_url: convertImageUrl(dish.image_url, req, restaurantId, categoryId)
        }));

        res.json(dishes);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Belirli bir restoranın sosyal medya bilgilerini getir
app.get('/restaurants/:restaurantId/settings/social', async(req, res) => {
    try {
        const { restaurantId } = req.params;
        const result = await pool.query('SELECT * FROM settings WHERE restaurant_id = $1', [restaurantId]);

        // Sorgu sonucunu log yapalım
        console.log(`\n🌐 SOSYAL MEDYA SORGUSU SONUCU: ${result.rows.length} kayıt bulundu`);

        if (result.rows.length > 0) {
            res.json(result.rows[0]);
        } else {
            res.status(404).json({ error: 'Settings not found' });
        }
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Uploads klasöründeki resimleri listeleyen endpoint - belirli bir restoran ve kategori için
app.get('/restaurants/:restaurantId/categories/:categoryId/images', async(req, res) => {
    try {
        const { restaurantId, categoryId } = req.params;
        const uploadsDir = path.join(__dirname, 'uploads', restaurantId, categoryId);

        // Klasörün varlığını kontrol et ve oluştur
        ensureDirectoryExists(uploadsDir);

        fs.readdir(uploadsDir, (err, files) => {
            if (err) {
                console.error('Klasör okunamadı:', err);
                return res.status(500).json({ error: 'Klasör okunamadı' });
            }

            // Sadece resim dosyalarını filtrele
            const imageFiles = files.filter(file => {
                const ext = path.extname(file).toLowerCase();
                return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].includes(ext);
            });

            // Her resim için URL oluştur - doğrudan istenen URL formatında
            const images = imageFiles.map(file => {
                return {
                    name: file,
                    url: `${req.protocol}://${req.hostname || 'localhost'}:${port}/uploads/${restaurantId}/${categoryId}/${file}`,
                    path: `uploads/${restaurantId}/${categoryId}/${file}`
                };
            });

            res.json(images);
        });
    } catch (err) {
        console.error('Resim listesi alınamadı:', err);
        res.status(500).json({ error: err.message });
    }
});

// Tüm resimleri listeleyen genel endpoint (geriye dönük uyumluluk için)
app.get('/uploads', async(req, res) => {
    try {
        const baseDir = path.join(__dirname, 'uploads');
        const images = [];

        // Klasörün varlığını kontrol et
        ensureDirectoryExists(baseDir);

        // Recursive olarak tüm dizinleri tara
        const scanDirectory = (dir, restaurantId = '', categoryId = '') => {
            const files = fs.readdirSync(dir);

            files.forEach(file => {
                const filePath = path.join(dir, file);
                const stats = fs.statSync(filePath);

                if (stats.isDirectory()) {
                    // Dizin yapısına göre restaurantId ve categoryId belirle
                    const newRestaurantId = restaurantId || file;
                    const newCategoryId = restaurantId ? (categoryId || file) : '';

                    scanDirectory(filePath, newRestaurantId, newCategoryId);
                } else {
                    const ext = path.extname(file).toLowerCase();
                    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].includes(ext)) {
                        // Dizin yapısından yolu oluştur
                        let relativePath = path.relative(baseDir, filePath).replace(/\\/g, '/');

                        images.push({
                            name: file,
                            url: `http://localhost:${port}/uploads/${relativePath}`,
                            path: `uploads/${relativePath}`,
                            restaurant_id: restaurantId,
                            category_id: categoryId
                        });
                    }
                }
            });
        };

        scanDirectory(baseDir);
        res.json(images);
    } catch (err) {
        console.error('Resim listesi alınamadı:', err);
        res.status(500).json({ error: err.message });
    }
});

// Authentication Endpoints
app.post('/auth/login', async(req, res) => {
    try {
        const { email, password } = req.body;

        // Eposta formatını kontrol et
        if (!email || !email.includes('@')) {
            return res.status(400).json({ error: 'Geçerli bir e-posta adresi giriniz' });
        }

        // Şifreyi kontrol et
        if (!password || password.length < 4) {
            return res.status(400).json({ error: 'Şifre en az 4 karakter olmalıdır' });
        }

        // Kullanıcıyı veritabanında ara
        const userResult = await pool.query(
            'SELECT * FROM users WHERE email = $1', [email]
        );

        // Kullanıcı bulunamadı mı?
        if (userResult.rows.length === 0) {
            return res.status(401).json({ error: 'E-posta veya şifre hatalı' });
        }

        const user = userResult.rows[0];

        // Şifre doğrulama
        const isPasswordValid = await bcrypt.compare(password, user.password);

        if (!isPasswordValid) {
            return res.status(401).json({ error: 'E-posta veya şifre hatalı' });
        }

        // JWT token oluştur
        const token = jwt.sign({
                userId: user.id,
                email: user.email,
                restaurantId: user.restaurant_id
            },
            JWT_SECRET, { expiresIn: '24h' }
        );

        // Kullanıcı bilgilerini döndür (şifre hariç)
        const { password: _, ...userWithoutPassword } = user;

        res.json({
            message: 'Giriş başarılı',
            user: userWithoutPassword,
            token
        });

    } catch (err) {
        console.error('Giriş hatası:', err);
        res.status(500).json({ error: 'Sunucu hatası' });
    }
});

// Kullanıcı kaydı endpoint'i
app.post('/auth/register', async(req, res) => {
    try {
        const { email, password, restaurantId } = req.body;

        // Temel doğrulamalar
        if (!email || !email.includes('@')) {
            return res.status(400).json({ error: 'Geçerli bir e-posta adresi giriniz' });
        }

        if (!password || password.length < 4) {
            return res.status(400).json({ error: 'Şifre en az 4 karakter olmalıdır' });
        }

        // E-posta mevcut mu kontrolü
        const existingUser = await pool.query(
            'SELECT * FROM users WHERE email = $1', [email]
        );

        if (existingUser.rows.length > 0) {
            return res.status(400).json({ error: 'Bu e-posta adresiyle kayıtlı bir kullanıcı zaten var' });
        }

        // Şifreyi hashle
        const passwordHash = await bcrypt.hash(password, 10);

        // Kullanıcı kaydı oluştur
        const newUser = await pool.query(
            'INSERT INTO users (email, password, restaurant_id) VALUES ($1, $2, $3) RETURNING id, email, restaurant_id, created_at', [email, passwordHash, restaurantId]
        );

        // JWT token oluştur
        const user = newUser.rows[0];
        const token = jwt.sign({
                userId: user.id,
                email: user.email,
                restaurantId: user.restaurant_id
            },
            JWT_SECRET, { expiresIn: '24h' }
        );

        res.status(201).json({
            message: 'Kullanıcı başarıyla oluşturuldu',
            user,
            token
        });

    } catch (err) {
        console.error('Kayıt hatası:', err);
        res.status(500).json({ error: 'Sunucu hatası' });
    }
});

// Authentication middleware - korumalı endpoint'ler için kullanılacak
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'Yetkilendirme gerekli' });
    }

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) {
            return res.status(403).json({ error: 'Token geçersiz veya süresi dolmuş' });
        }

        req.user = user;
        next();
    });
};

// Örnek korumalı endpoint - kullanıcı bilgilerini döndürür
app.get('/auth/me', authenticateToken, async(req, res) => {
    try {
        const userResult = await pool.query(
            'SELECT id, email, restaurant_id, created_at FROM users WHERE id = $1', [req.user.userId]
        );

        if (userResult.rows.length === 0) {
            return res.status(404).json({ error: 'Kullanıcı bulunamadı' });
        }

        res.json(userResult.rows[0]);
    } catch (err) {
        console.error('Kullanıcı bilgileri hatası:', err);
        res.status(500).json({ error: 'Sunucu hatası' });
    }
});

// Yemek (menu item) güncelleme endpoint'i
app.put('/restaurants/:restaurantId/categories/:categoryId/dishes/:dishId', authenticateToken, async(req, res) => {
    // Get a client from the pool for a dedicated connection with transaction
    const client = await pool.connect();

    try {
        const { restaurantId, categoryId, dishId } = req.params;
        const { name, description, price, image_url, imageBase64 } = req.body;

        // Log the PUT request body in detail (masking the base64 data for brevity)
        console.log('\n📥 GELEN GÜNCELLEME VERİLERİ:');
        const logBody = {...req.body };
        if (logBody.imageBase64) {
            logBody.imageBase64 = logBody.imageBase64.substring(0, 50) + '... [kısaltıldı]';
        }
        console.log(JSON.stringify({
            params: { restaurantId, categoryId, dishId },
            body: logBody
        }, null, 2));
        console.log('------------------------------');

        // Kullanıcının bu restoran için yetkisi var mı kontrol et
        if (req.user.restaurantId != restaurantId) {
            return res.status(403).json({ error: 'Bu restoranın menüsünü güncelleme yetkiniz yok' });
        }

        // Begin transaction
        await client.query('BEGIN');

        // Güncellenecek yemeğin var olup olmadığını kontrol et
        const checkDishResult = await client.query(
            'SELECT * FROM dishes WHERE id = $1 AND restaurant_id = $2 AND category_id = $3', [dishId, restaurantId, categoryId]
        );

        if (checkDishResult.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ error: 'Güncellemek istediğiniz yemek bulunamadı' });
        }

        // Geçerli yemek verisini al
        const currentDish = checkDishResult.rows[0];

        // Güncelleme için kullanılacak değerleri belirle (belirtilmemişse mevcut değerler kullanılır)
        const updatedName = name !== undefined ? name : currentDish.name;
        const updatedDescription = description !== undefined ? description : currentDish.description;
        const updatedPrice = price !== undefined ? price : currentDish.price;
        let updatedImageUrl = image_url !== undefined ? image_url : currentDish.image_url;

        // Eğer base64 resim varsa, kaydet
        if (imageBase64) {
            // Dosya adını oluştur, id ile birlikte (örn: dish_123.jpg)
            const fileName = `dish_${dishId}.jpg`;

            // Base64 resmi kaydet
            const savedImagePath = saveBase64Image(imageBase64, restaurantId, categoryId, fileName);
            if (savedImagePath) {
                updatedImageUrl = savedImagePath;
            }
        }

        // Yemeği güncelle
        const updateResult = await client.query(
            `UPDATE dishes 
             SET name = $1, description = $2, price = $3, image_url = $4, updated_at = CURRENT_TIMESTAMP
             WHERE id = $5 AND restaurant_id = $6 AND category_id = $7
             RETURNING *`, [updatedName, updatedDescription, updatedPrice, updatedImageUrl, dishId, restaurantId, categoryId]
        );

        // Commit the transaction
        await client.query('COMMIT');

        // URL'leri dönüştür
        const updatedDish = {
            ...updateResult.rows[0],
            image_url: convertImageUrl(updateResult.rows[0].image_url, req, restaurantId, categoryId)
        };

        res.json({
            message: 'Yemek başarıyla güncellendi',
            dish: updatedDish
        });

    } catch (err) {
        // Rollback in case of error
        await client.query('ROLLBACK');
        console.error('Yemek güncelleme hatası:', err);
        res.status(500).json({ error: 'Sunucu hatası' });
    } finally {
        // Release the client back to the pool
        client.release();
    }
});

// Yeni yemek ekleme endpoint'i
app.post('/restaurants/:restaurantId/categories/:categoryId/dishes', authenticateToken, async(req, res) => {
    const client = await pool.connect();

    try {
        const { restaurantId, categoryId } = req.params;
        const { name, description, price, image_url, imageBase64 } = req.body;

        console.log('\n🍽️ YENİ YEMEK EKLEME İSTEĞİ:');
        console.log(`Restoran ID: ${restaurantId}, Kategori ID: ${categoryId}`);
        console.log(`Yemek Adı: ${name}`);
        console.log(`Base64 Görsel Mevcut: ${imageBase64 ? 'EVET' : 'HAYIR'}`);

        // Kullanıcının bu restoran için yetkisi var mı kontrol et
        if (req.user.restaurantId != restaurantId) {
            return res.status(403).json({ error: 'Bu restorana yemek ekleme yetkiniz yok' });
        }

        // Zorunlu alanları kontrol et
        if (!name || !price) {
            return res.status(400).json({ error: 'Yemek adı ve fiyatı zorunludur' });
        }

        // Begin transaction
        await client.query('BEGIN');

        // Önce yemeği ekle (görüntüsüz) - ID almak için
        const insertResult = await client.query(
            `INSERT INTO dishes (restaurant_id, category_id, name, description, price)
             VALUES ($1, $2, $3, $4, $5)
             RETURNING *`, [restaurantId, categoryId, name, description || '', price]
        );

        const newDishId = insertResult.rows[0].id;
        console.log(`✅ Yemek kaydedildi, ID: ${newDishId}`);

        let imagePath = image_url || null;

        // Eğer base64 resim varsa, kaydet
        if (imageBase64) {
            console.log(`🖼️ Base64 görsel işleniyor...`);
            // Dosya adını oluştur, id ile birlikte (örn: dish_123.jpg)
            const fileName = `dish_${newDishId}.jpg`;

            // Base64 resmi kaydet
            imagePath = saveBase64Image(imageBase64, restaurantId, categoryId, fileName);

            // Yemek kaydını görüntü yolu ile güncelle
            if (imagePath) {
                console.log(`🔄 Yemek kaydı görsel yolu ile güncelleniyor: ${imagePath}`);
                await client.query(
                    `UPDATE dishes SET image_url = $1 WHERE id = $2`, [imagePath, newDishId]
                );

                // Güncellenmiş yemek bilgisini al
                const updatedResult = await client.query(
                    `SELECT * FROM dishes WHERE id = $1`, [newDishId]
                );

                insertResult.rows[0] = updatedResult.rows[0];
                console.log(`✅ Yemek kaydı güncellendi, görsel yolu: ${updatedResult.rows[0].image_url}`);
            } else {
                console.error(`❌ Görsel kaydedilemedi!`);
            }
        } else {
            console.log(`ℹ️ Base64 görsel yok, yemek görselsiz oluşturuldu`);
        }

        // Commit the transaction
        await client.query('COMMIT');
        console.log(`✅ İşlem tamamlandı (COMMIT)`);

        // URL'leri dönüştür
        const newDish = {
            ...insertResult.rows[0],
            image_url: convertImageUrl(insertResult.rows[0].image_url, req, restaurantId, categoryId)
        };

        res.status(201).json({
            message: 'Yemek başarıyla eklendi',
            dish: newDish
        });

    } catch (err) {
        // Rollback in case of error
        await client.query('ROLLBACK');
        console.error('❌ Yemek ekleme hatası:', err);
        res.status(500).json({ error: 'Sunucu hatası' });
    } finally {
        // Release the client back to the pool
        client.release();
    }
});

// Yeni kategori ekleme endpoint'i
app.post('/restaurants/:restaurantId/categories', authenticateToken, async(req, res) => {
    const client = await pool.connect();

    try {
        const { restaurantId } = req.params;
        const { name, imageBase64 } = req.body;

        console.log('\n📋 YENİ KATEGORİ EKLEME İSTEĞİ:');
        console.log(`Restoran ID: ${restaurantId}`);
        console.log(`Kategori Adı: ${name}`);
        console.log(`Base64 Görsel Mevcut: ${imageBase64 ? 'EVET' : 'HAYIR'}`);

        // Kullanıcının bu restoran için yetkisi var mı kontrol et
        if (req.user.restaurantId != restaurantId) {
            return res.status(403).json({ error: 'Bu restorana kategori ekleme yetkiniz yok' });
        }

        // Zorunlu alanları kontrol et
        if (!name) {
            return res.status(400).json({ error: 'Kategori adı zorunludur' });
        }

        // Begin transaction
        await client.query('BEGIN');

        // Önce kategori ekle (görüntüsüz) - ID almak için
        const insertResult = await client.query(
            `INSERT INTO categories (restaurant_id, name)
             VALUES ($1, $2)
             RETURNING *`, [restaurantId, name]
        );

        const newCategoryId = insertResult.rows[0].id;
        console.log(`✅ Kategori kaydedildi, ID: ${newCategoryId}`);

        // Eğer base64 resim varsa, kaydet
        if (imageBase64) {
            console.log(`🖼️ Base64 görsel işleniyor...`);
            // Dosya adını oluştur, id ile birlikte (örn: category_123.jpg)
            const fileName = `category_${newCategoryId}.jpg`;

            // Base64 resmi kaydet
            const imagePath = saveBase64Image(imageBase64, restaurantId, newCategoryId, fileName);

            // Kategori kaydını görüntü yolu ile güncelle
            if (imagePath) {
                console.log(`🔄 Kategori kaydı görsel yolu ile güncelleniyor: ${imagePath}`);
                await client.query(
                    `UPDATE categories SET image_url = $1 WHERE id = $2`, [imagePath, newCategoryId]
                );

                // Güncellenmiş kategori bilgisini al
                const updatedResult = await client.query(
                    `SELECT * FROM categories WHERE id = $1`, [newCategoryId]
                );

                insertResult.rows[0] = updatedResult.rows[0];
                console.log(`✅ Kategori kaydı güncellendi, görsel yolu: ${updatedResult.rows[0].image_url}`);
            } else {
                console.error(`❌ Görsel kaydedilemedi!`);
            }
        } else {
            console.log(`ℹ️ Base64 görsel yok, kategori görselsiz oluşturuldu`);
        }

        // Commit the transaction
        await client.query('COMMIT');
        console.log(`✅ İşlem tamamlandı (COMMIT)`);

        // URL'leri dönüştür
        const newCategory = {
            ...insertResult.rows[0],
            image_url: convertImageUrl(insertResult.rows[0].image_url, req, restaurantId, newCategoryId)
        };

        res.status(201).json({
            message: 'Kategori başarıyla eklendi',
            category: newCategory
        });

    } catch (err) {
        // Rollback in case of error
        await client.query('ROLLBACK');
        console.error('❌ Kategori ekleme hatası:', err);
        res.status(500).json({ error: 'Sunucu hatası' });
    } finally {
        // Release the client back to the pool
        client.release();
    }
});

// Yemek silme endpoint'i
app.delete('/restaurants/:restaurantId/categories/:categoryId/dishes/:dishId', authenticateToken, async(req, res) => {
    const client = await pool.connect();

    try {
        const { restaurantId, categoryId, dishId } = req.params;

        // Kullanıcının bu restoran için yetkisi var mı kontrol et
        if (req.user.restaurantId != restaurantId) {
            return res.status(403).json({ error: 'Bu restoranın yemeklerini silme yetkiniz yok' });
        }

        // Begin transaction
        await client.query('BEGIN');

        // Silinecek yemeğin var olup olmadığını kontrol et ve resim yolunu al
        const checkDishResult = await client.query(
            'SELECT * FROM dishes WHERE id = $1 AND restaurant_id = $2 AND category_id = $3', [dishId, restaurantId, categoryId]
        );

        if (checkDishResult.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ error: 'Silmek istediğiniz yemek bulunamadı' });
        }

        // Resim yolunu al
        const imageUrl = checkDishResult.rows[0].image_url;

        // Yemeği sil
        await client.query(
            'DELETE FROM dishes WHERE id = $1 AND restaurant_id = $2 AND category_id = $3', [dishId, restaurantId, categoryId]
        );

        // Commit the transaction
        await client.query('COMMIT');

        // İşlem başarılı olduktan sonra ilgili resmi sil (varsa)
        if (imageUrl) {
            try {
                console.log(`🗑️ Resim silme işlemi başlatılıyor: ${imageUrl}`);

                // Resim dosya yolunu oluştur
                let imagePath;
                if (imageUrl.includes('uploads/')) {
                    imagePath = path.join(__dirname, imageUrl);
                } else {
                    imagePath = path.join(__dirname, 'uploads', restaurantId.toString(), categoryId.toString(), imageUrl);
                }

                // Dosya var mı kontrol et
                if (fs.existsSync(imagePath)) {
                    // Sadece dish_ID.jpg formatındaki dosyaları sil (yanlışlıkla başka dosya silinmesin)
                    const fileName = path.basename(imagePath);
                    if (fileName.startsWith(`dish_${dishId}.`) || fileName === imageUrl) {
                        fs.unlinkSync(imagePath);
                        console.log(`✅ Resim başarıyla silindi: ${imagePath}`);
                    } else {
                        console.log(`⚠️ Güvenlik nedeniyle dosya silinmedi. Beklenen format: dish_${dishId}.*`);
                    }
                } else {
                    console.log(`⚠️ Silinecek dosya bulunamadı: ${imagePath}`);
                }
            } catch (fileErr) {
                // Resim silme hatası işlemi etkilemesin
                console.error(`❌ Resim silme hatası:`, fileErr);
            }
        }

        res.json({
            message: 'Yemek başarıyla silindi',
            id: dishId
        });

    } catch (err) {
        // Rollback in case of error
        await client.query('ROLLBACK');
        console.error('Yemek silme hatası:', err);
        res.status(500).json({ error: 'Sunucu hatası' });
    } finally {
        // Release the client back to the pool
        client.release();
    }
});

// Kategori silme endpoint'i
app.delete('/restaurants/:restaurantId/categories/:categoryId', authenticateToken, async(req, res) => {
    const client = await pool.connect();

    try {
        const { restaurantId, categoryId } = req.params;

        // Kullanıcının bu restoran için yetkisi var mı kontrol et
        if (req.user.restaurantId != restaurantId) {
            return res.status(403).json({ error: 'Bu restoranın kategorilerini silme yetkiniz yok' });
        }

        // Begin transaction
        await client.query('BEGIN');

        // Silinecek kategorinin var olup olmadığını kontrol et ve resim yolunu al
        const checkCategoryResult = await client.query(
            'SELECT * FROM categories WHERE id = $1 AND restaurant_id = $2', [categoryId, restaurantId]
        );

        if (checkCategoryResult.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ error: 'Silmek istediğiniz kategori bulunamadı' });
        }

        // Resim yolunu al
        const imageUrl = checkCategoryResult.rows[0].image_url;

        // Bu kategoriye bağlı yemekleri kontrol et
        const relatedDishesResult = await client.query(
            'SELECT COUNT(*) FROM dishes WHERE category_id = $1 AND restaurant_id = $2', [categoryId, restaurantId]
        );

        const dishCount = parseInt(relatedDishesResult.rows[0].count);
        if (dishCount > 0) {
            await client.query('ROLLBACK');
            return res.status(400).json({
                error: 'Bu kategori silinemiyor çünkü içinde yemekler var',
                dishCount
            });
        }

        // Kategoriyi sil
        await client.query(
            'DELETE FROM categories WHERE id = $1 AND restaurant_id = $2', [categoryId, restaurantId]
        );

        // Commit the transaction
        await client.query('COMMIT');

        // İşlem başarılı olduktan sonra ilgili resmi sil (varsa)
        if (imageUrl) {
            try {
                console.log(`🗑️ Kategori resmi silme işlemi başlatılıyor: ${imageUrl}`);

                // Resim dosya yolunu oluştur
                let imagePath;
                if (imageUrl.includes('uploads/')) {
                    imagePath = path.join(__dirname, imageUrl);
                } else {
                    imagePath = path.join(__dirname, 'uploads', restaurantId.toString(), categoryId.toString(), imageUrl);
                }

                // Dosya var mı kontrol et
                if (fs.existsSync(imagePath)) {
                    // Sadece category_ID.jpg formatındaki dosyaları sil (yanlışlıkla başka dosya silinmesin)
                    const fileName = path.basename(imagePath);
                    if (fileName.startsWith(`category_${categoryId}.`) || fileName === imageUrl) {
                        fs.unlinkSync(imagePath);
                        console.log(`✅ Kategori resmi başarıyla silindi: ${imagePath}`);
                    } else {
                        console.log(`⚠️ Güvenlik nedeniyle dosya silinmedi. Beklenen format: category_${categoryId}.*`);
                    }
                } else {
                    console.log(`⚠️ Silinecek dosya bulunamadı: ${imagePath}`);
                }

                // Kategori klasörünü sil (boş ise)
                const categoryDir = path.join(__dirname, 'uploads', restaurantId.toString(), categoryId.toString());
                if (fs.existsSync(categoryDir)) {
                    const files = fs.readdirSync(categoryDir);
                    if (files.length === 0) {
                        fs.rmdirSync(categoryDir);
                        console.log(`✅ Boş kategori klasörü silindi: ${categoryDir}`);
                    }
                }
            } catch (fileErr) {
                // Resim silme hatası işlemi etkilemesin
                console.error(`❌ Resim silme hatası:`, fileErr);
            }
        }

        res.json({
            message: 'Kategori başarıyla silindi',
            id: categoryId
        });

    } catch (err) {
        // Rollback in case of error
        await client.query('ROLLBACK');
        console.error('Kategori silme hatası:', err);
        res.status(500).json({ error: 'Sunucu hatası' });
    } finally {
        // Release the client back to the pool
        client.release();
    }
});

app.listen(port, () => {
    console.log(`Server running on http://localhost:${port}`);
});