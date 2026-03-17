class WorkerAssignment {
  const WorkerAssignment({
    required this.name,
    this.workerType = '',
    this.workFrom = '',
  });

  final String name;
  final String workerType;
  final String workFrom;

  Map<String, dynamic> toJson() => {
        'name': name,
        'worker_type': workerType,
        'work_from': workFrom,
      };

  static WorkerAssignment fromJson(Map<String, dynamic> j) {
    return WorkerAssignment(
      name: j['name']?.toString() ?? '',
      workerType: j['worker_type']?.toString() ?? '',
      workFrom: j['work_from']?.toString() ?? '',
    );
  }

  static WorkerAssignment fromFarmWorkerRow(Map<String, dynamic> row) {
    return WorkerAssignment(
      name: row['name']?.toString() ?? '',
      workerType: row['worker_type']?.toString() ?? '',
      workFrom: row['work_from']?.toString() ?? '',
    );
  }

  String get chipLabel {
    final parts = <String>[name];
    if (workerType.isNotEmpty) parts.add(workerType);
    if (workFrom.isNotEmpty) parts.add(workFrom);
    return parts.join(' · ');
  }

  @override
  bool operator ==(Object other) =>
      other is WorkerAssignment &&
      name == other.name &&
      workerType == other.workerType &&
      workFrom == other.workFrom;

  @override
  int get hashCode => Object.hash(name, workerType, workFrom);
}
