import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ficha_de_exercicios/model/exercicio.dart';
import 'package:flutter/material.dart';

class FormExercicioPage extends StatefulWidget {
  final String uid;
  final String rotinaId;
  final Exercicio? exercicio;

  const FormExercicioPage({
    super.key,
    required this.uid,
    required this.rotinaId,
    this.exercicio,
  });

  @override
  State<FormExercicioPage> createState() => _FormExercicioPageState();
}

class _FormExercicioPageState extends State<FormExercicioPage> {
  final _formKey = GlobalKey<FormState>();

  final nome = TextEditingController();
  final series = TextEditingController();
  final repeticoes = TextEditingController();
  final carga = TextEditingController();
  final observacoes = TextEditingController();

  String grupoMuscular = "Peito";
  String equipamento = "Halteres";

  final grupos = [
    "Peito", "Costas", "Ombros", "Bíceps", "Tríceps", "Quadríceps", "Glúteos", "Posterior"
  ];

  final equipamentos = [
    "Halteres", "Barra", "Máquina", "Cabo", "Peso corporal"
  ];

  CollectionReference get exerciciosCollection => FirebaseFirestore.instance
      .collection('rotinas')
      .doc(widget.uid)
      .collection('minhas_rotinas')
      .doc(widget.rotinaId)
      .collection('exercicios');

  @override
  void initState() {
    super.initState();
    if (widget.exercicio != null) {
      final ex = widget.exercicio!;
      nome.text = ex.nome;
      series.text = ex.series.toString();
      repeticoes.text = ex.repeticoes.toString();
      carga.text = ex.carga.toString();
      grupoMuscular = ex.grupoMuscular;
      equipamento = ex.tipoEquipamento;
      observacoes.text = ex.observacoes ?? '';
    }
  }

  Future<void> salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final dados = {
      'nome': nome.text.trim(),
      'grupoMuscular': grupoMuscular,
      'tipoEquipamento': equipamento,
      'series': int.parse(series.text.trim()),
      'repeticoes': int.parse(repeticoes.text.trim()),
      'carga': double.parse(carga.text.trim()),
      'observacoes': observacoes.text.trim(),
    };

    try {
      if (widget.exercicio == null) {
        // Apenas novos exercícios recebem createdAt
        dados['createdAt'] = Timestamp.now();
        await exerciciosCollection.add(dados);
      } else {
        // Atualizando exercício existente: NÃO altere createdAt
        await exerciciosCollection.doc(widget.exercicio!.id).update(dados);
      }
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: $e')));
    }

  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.purpleAccent),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.purple, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.purpleAccent, width: 2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: Text(widget.exercicio == null ? "Novo Exercício" : "Editar Exercício"),
        backgroundColor: Colors.purple[400],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Nome
              TextFormField(
                controller: nome,
                decoration: _inputDecoration("Nome do exercício"),
                style: const TextStyle(color: Colors.white),
                validator: (v) => v!.isEmpty ? "Informe um nome" : null,
              ),
              const SizedBox(height: 16),

              // Grupo Muscular
              DropdownButtonFormField(
                value: grupoMuscular,
                items: grupos
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => grupoMuscular = v!),
                decoration: _inputDecoration("Grupo Muscular"),
                dropdownColor: const Color(0xFF2C2C2C),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),

              // Equipamento
              DropdownButtonFormField(
                value: equipamento,
                items: equipamentos
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => equipamento = v!),
                decoration: _inputDecoration("Equipamento"),
                dropdownColor: const Color(0xFF2C2C2C),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),

              // Séries, Repetições, Carga
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: series,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration("Séries"),
                      style: const TextStyle(color: Colors.white),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Informe o número de séries";
                        final valor = double.tryParse(v);
                        if (valor == null) return "Use apenas números (ex: 10.5)";
                        if (valor > 50) return "Insira uma carga válida";
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: repeticoes,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration("Repetições"),
                      style: const TextStyle(color: Colors.white),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Informe as repetições";
                        final valor = double.tryParse(v);
                        if (valor == null) return "Use apenas números (ex: 10.5)";
                        switch (grupoMuscular) {
                          case "Peito":
                          case "Costas":
                          case "Bíceps":
                          case "Tríceps":
                          case "Ombros":
                            if (valor > 50) return "Insira uma carga válida";
                            break;
                          case "Quadríceps":
                          case "Glúteos":
                          case "Posterior":
                            if (valor > 200) return "Insira uma carga válida";
                            break;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: carga,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration("Carga (kg)"),
                      style: const TextStyle(color: Colors.white),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Informe a carga";
                        final valor = double.tryParse(v);
                        if (valor == null) return "Use apenas números (ex: 10.5)";
                        switch (grupoMuscular) {
                          case "Peito":
                          case "Costas":
                            if (valor > 300) return "Insira uma carga válida";
                            break;
                          case "Bíceps":
                          case "Tríceps":
                          case "Ombros":
                            if (valor > 200) return "Insira uma carga válida";
                            break;
                          case "Quadríceps":
                          case "Glúteos":
                          case "Posterior":
                            if (valor > 2000) return "Insira uma carga válida";
                            break;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Observações
              TextFormField(
                controller: observacoes,
                decoration: _inputDecoration("Observações"),
                keyboardType: TextInputType.multiline,
                minLines: 3,
                maxLines: null,
                style: const TextStyle(color: Colors.white),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text("Salvar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
