import 'package:cloud_firestore/cloud_firestore.dart';

class Exercicio {
  String? id;
  String nome;
  String grupoMuscular;
  String tipoEquipamento;
  int series;
  int repeticoes;
  double carga;
  String? observacoes;

  Exercicio({
    this.id,
    required this.nome,
    required this.grupoMuscular,
    required this.tipoEquipamento,
    required this.series,
    required this.repeticoes,
    required this.carga,
    this.observacoes,
  });

  // Cria um objeto Exercicio a partir de um DocumentSnapshot do Firestore
  factory Exercicio.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Exercicio(
      id: doc.id,
      nome: data['nome'] ?? '',
      grupoMuscular: data['grupoMuscular'] ?? '',
      tipoEquipamento: data['tipoEquipamento'] ?? '',
      series: data['series'] ?? 0,
      repeticoes: data['repeticoes'] ?? 0,
      carga: (data['carga'] ?? 0).toDouble(),
      observacoes: data['observacoes'],
    );
  }

  // Converte para Map<String, dynamic> para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'grupoMuscular': grupoMuscular,
      'tipoEquipamento': tipoEquipamento,
      'series': series,
      'repeticoes': repeticoes,
      'carga': carga,
      'observacoes': observacoes,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Converte para Map<String, dynamic> sem o createdAt (para update)
  Map<String, dynamic> toMapUpdate() {
    return {
      'nome': nome,
      'grupoMuscular': grupoMuscular,
      'tipoEquipamento': tipoEquipamento,
      'series': series,
      'repeticoes': repeticoes,
      'carga': carga,
      'observacoes': observacoes,
    };
  }
}
