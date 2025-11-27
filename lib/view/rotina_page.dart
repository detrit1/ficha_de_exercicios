import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'form_exercicio_page.dart';
import 'package:ficha_de_exercicios/model/exercicio.dart';

class RotinaPage extends StatelessWidget {
  final String rotinaId;
  final String rotinaNome;
  final String uid;

  const RotinaPage({
    super.key,
    required this.rotinaId,
    required this.rotinaNome,
    required this.uid,
  });

  IconData getIconForEquipment(String equipamento) {
    switch (equipamento.toLowerCase()) {
      case "halteres":
      case "barra":
        return Icons.fitness_center;
      case "máquina":
        return Icons.settings;
      case "cabo":
        return Icons.cable;
      case "peso corporal":
        return Icons.accessibility;
      default:
        return Icons.fitness_center;
    }
  }

  void confirmarExclusao(BuildContext context, CollectionReference collection, String id, String nome) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text("Excluir exercício?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text("Deseja realmente excluir '$nome'?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.purple)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await collection.doc(id).delete();
              Navigator.pop(context);
            },
            child: const Text("Excluir", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exerciciosCollection = FirebaseFirestore.instance
        .collection('rotinas')
        .doc(uid)
        .collection('minhas_rotinas')
        .doc(rotinaId)
        .collection('exercicios');

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: Text("Rotina: $rotinaNome"),
        backgroundColor: Colors.purple[400],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple[400],
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FormExercicioPage(
                uid: uid,
                rotinaId: rotinaId,
              ),
            ),
          );
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: exerciciosCollection.orderBy('createdAt', descending: false).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('Erro: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center, size: 80, color: Colors.purple[300]),
                  const SizedBox(height: 20),
                  const Text(
                    "Nenhum exercício ainda…",
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Clique no + para adicionar seu primeiro exercício!",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final exercicios = docs.map((doc) => Exercicio.fromFirestore(doc)).toList();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: ListView.builder(
              itemCount: exercicios.length,
              itemBuilder: (context, index) {
                final e = exercicios[index];

                return Dismissible(
                  key: Key(e.id!),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF2C2C2C),
                        title: const Text("Confirmar exclusão", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        content: Text("Deseja realmente excluir '${e.nome}'?", style: const TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("Cancelar", style: TextStyle(color: Colors.purple)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("Excluir", style: TextStyle(color: Colors.black)),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) async {
                    await exerciciosCollection.doc(e.id).delete();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple, width: 2),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final atualizado = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FormExercicioPage(
                              uid: uid,
                              rotinaId: rotinaId,
                              exercicio: e,
                            ),
                          ),
                        );

                        if (atualizado == true) {
                          (context as Element).markNeedsBuild();
                        }
                      },

                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              getIconForEquipment(e.tipoEquipamento),
                              color: Colors.purple,
                              size: 60,
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center, // centraliza horizontalmente
                                children: [
                                  // Nome do exercício
                                  Text(
                                    e.nome,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Grupo Muscular • Séries x Repetições • Carga
                                  Text(
                                    "${e.grupoMuscular} • ${e.series} x ${e.repeticoes} • ${e.carga} kg",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),

                                  // Observações (mantidas alinhadas à esquerda)
                                  if (e.observacoes != null && e.observacoes!.trim().isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.sticky_note_2, size: 18, color: Colors.white38),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            e.observacoes!,
                                            style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 13,
                                              fontStyle: FontStyle.italic,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
