import '../../domain/entities/party.dart';
import '../../domain/repositories/party_repository.dart';
import '../datasources/local/party_local_datasource.dart';
import '../models/party_model.dart';

class PartyRepositoryImpl implements PartyRepository {
  final PartyLocalDataSource _dataSource;

  const PartyRepositoryImpl(this._dataSource);

  @override
  Future<Party?> getById(String id) async {
    final data = await _dataSource.getById(id);

    if (data == null) {
      return null;
    }

    return PartyModel.fromMap(data).toEntity();
  }

  @override
  Future<List<Party>> search(String query) async {
    final data = await _dataSource.search(query);

    return data
        .map(PartyModel.fromMap)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<void> create(Party party) async {
    final model = PartyModel.fromEntity(party);

    await _dataSource.insert(model.toMap());
  }

  @override
  Future<void> update(Party party) async {
    final model = PartyModel.fromEntity(party);

    await _dataSource.update(party.id, model.toMap());
  }
}
