/// Interface contract for the local storage service.
abstract class StorageService {
  Future<void> put(String box, String key, dynamic value);
  dynamic get(String box, String key, {dynamic defaultValue});
  Future<void> delete(String box, String key);
  Map<dynamic, dynamic> getAll(String box);
  Future<void> clear(String box);
}
