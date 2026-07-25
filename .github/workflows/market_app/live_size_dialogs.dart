import 'package:flutter/material.dart';

class LiveSizeSetup {
  const LiveSizeSetup({
    required this.widthInches,
    required this.heightInches,
    required this.unit,
  });

  final double widthInches;
  final double heightInches;
  final String unit;
}

class ExactSizeRequest {
  const ExactSizeRequest({
    required this.dimension,
    required this.value,
  });

  final String dimension;
  final double value;
}

Future<LiveSizeSetup?> showLiveSizeSetupDialog(
  BuildContext context, {
  double? existingWidthInches,
  double? existingHeightInches,
  String existingUnit = 'in',
}) async {
  var selectedPreset = 'Letter';
  var selectedUnit = existingUnit;
  final widthController = TextEditingController();
  final heightController = TextEditingController();

  void setValues(
    double width,
    double height,
    String unit,
  ) {
    selectedUnit = unit;

    widthController.text = width.toStringAsFixed(
      width.truncateToDouble() == width ? 0 : 2,
    );

    heightController.text = height.toStringAsFixed(
      height.truncateToDouble() == height ? 0 : 2,
    );
  }

  if (existingWidthInches != null &&
      existingHeightInches != null) {
    final factor =
        selectedUnit == 'cm' ? 2.54 : 1.0;

    setValues(
      existingWidthInches * factor,
      existingHeightInches * factor,
      selectedUnit,
    );

    selectedPreset = 'Custom';
  } else {
    setValues(
      8.5,
      11,
      'in',
    );
  }

  final result = await showDialog<LiveSizeSetup>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (
          context,
          setDialogState,
        ) {
          void applyPreset(String preset) {
            setDialogState(() {
              selectedPreset = preset;

              switch (preset) {
                case 'Letter':
                  setValues(
                    8.5,
                    11,
                    'in',
                  );
                  break;

                case 'A4':
                  setValues(
                    21,
                    29.7,
                    'cm',
                  );
                  break;

                case '11 × 14':
                  setValues(
                    11,
                    14,
                    'in',
                  );
                  break;

                case '16 × 20':
                  setValues(
                    16,
                    20,
                    'in',
                  );
                  break;

                case 'Custom':
                  break;
              }
            });
          }

          return AlertDialog(
            title: const Text(
              'Calibrate Live Size',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose the real size of the '
                    'paper or canvas. You will '
                    'then tap its top-left and '
                    'bottom-right corners.',
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  DropdownButtonFormField<String>(
                    key: ValueKey(
                      selectedPreset,
                    ),
                    initialValue:
                        selectedPreset,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Surface preset',
                      border:
                          OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Letter',
                        child: Text(
                          'Letter — 8.5 × 11 in',
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'A4',
                        child: Text(
                          'A4 — 21 × 29.7 cm',
                        ),
                      ),
                      DropdownMenuItem(
                        value: '11 × 14',
                        child: Text(
                          'Canvas — 11 × 14 in',
                        ),
                      ),
                      DropdownMenuItem(
                        value: '16 × 20',
                        child: Text(
                          'Canvas — 16 × 20 in',
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Custom',
                        child: Text(
                          'Custom size',
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        applyPreset(value);
                      }
                    },
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller:
                              widthController,
                          keyboardType:
                              const TextInputType
                                  .numberWithOptions(
                            decimal: true,
                          ),
                          decoration:
                              const InputDecoration(
                            labelText: 'Width',
                            border:
                                OutlineInputBorder(),
                          ),
                          onChanged: (_) {
                            setDialogState(() {
                              selectedPreset =
                                  'Custom';
                            });
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: TextField(
                          controller:
                              heightController,
                          keyboardType:
                              const TextInputType
                                  .numberWithOptions(
                            decimal: true,
                          ),
                          decoration:
                              const InputDecoration(
                            labelText: 'Height',
                            border:
                                OutlineInputBorder(),
                          ),
                          onChanged: (_) {
                            setDialogState(() {
                              selectedPreset =
                                  'Custom';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child:
                            DropdownButtonFormField<
                                String>(
                          key: ValueKey(
                            selectedUnit,
                          ),
                          initialValue:
                              selectedUnit,
                          decoration:
                              const InputDecoration(
                            labelText: 'Unit',
                            border:
                                OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'in',
                              child: Text(
                                'Inches',
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'cm',
                              child: Text(
                                'Centimeters',
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null ||
                                value ==
                                    selectedUnit) {
                              return;
                            }

                            final width =
                                double.tryParse(
                              widthController.text,
                            );

                            final height =
                                double.tryParse(
                              heightController.text,
                            );

                            setDialogState(() {
                              if (width != null &&
                                  height != null) {
                                final conversion =
                                    value == 'cm'
                                        ? 2.54
                                        : 1 / 2.54;

                                widthController.text =
                                    (width *
                                            conversion)
                                        .toStringAsFixed(
                                  2,
                                );

                                heightController.text =
                                    (height *
                                            conversion)
                                        .toStringAsFixed(
                                  2,
                                );
                              }

                              selectedUnit = value;
                              selectedPreset =
                                  'Custom';
                            });
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            final oldWidth =
                                widthController.text;

                            widthController.text =
                                heightController.text;

                            heightController.text =
                                oldWidth;

                            selectedPreset =
                                'Custom';
                          });
                        },
                        icon: const Icon(
                          Icons
                              .swap_horiz_rounded,
                        ),
                        label: const Text(
                          'Rotate',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  const Text(
                    'Recalibrate whenever the '
                    'phone height or position '
                    'changes.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                  );
                },
                child: const Text(
                  'Cancel',
                ),
              ),
              FilledButton(
                onPressed: () {
                  final width =
                      double.tryParse(
                    widthController.text,
                  );

                  final height =
                      double.tryParse(
                    heightController.text,
                  );

                  if (width == null ||
                      height == null ||
                      width <= 0 ||
                      height <= 0) {
                    return;
                  }

                  final divisor =
                      selectedUnit == 'cm'
                          ? 2.54
                          : 1.0;

                  Navigator.pop(
                    dialogContext,
                    LiveSizeSetup(
                      widthInches:
                          width / divisor,
                      heightInches:
                          height / divisor,
                      unit: selectedUnit,
                    ),
                  );
                },
                child: const Text(
                  'Start calibration',
                ),
              ),
            ],
          );
        },
      );
    },
  );

  widthController.dispose();
  heightController.dispose();

  return result;
}

Future<String?> showLiveSizeActionsDialog(
  BuildContext context, {
  required String measurement,
  required String unit,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text(
          'Live Size',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              measurement,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            const Text(
              'Measurements remain accurate '
              'while the phone stays in the '
              'calibrated position.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                'disable',
              );
            },
            child: const Text(
              'Turn off',
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                'unit',
              );
            },
            child: Text(
              unit == 'cm'
                  ? 'Show inches'
                  : 'Show cm',
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                'exact',
              );
            },
            child: const Text(
              'Exact size',
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                'recalibrate',
              );
            },
            child: const Text(
              'Recalibrate',
            ),
          ),
        ],
      );
    },
  );
}

Future<ExactSizeRequest?> showExactSizeDialog(
  BuildContext context, {
  required Size current,
  required String unit,
}) async {
  var dimension = 'width';

  final controller = TextEditingController(
    text: current.width.toStringAsFixed(2),
  );

  final result =
      await showDialog<ExactSizeRequest>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (
          context,
          setDialogState,
        ) {
          return AlertDialog(
            title: const Text(
              'Set exact image size',
            ),
            content: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey(
                    dimension,
                  ),
                  initialValue: dimension,
                  decoration:
                      const InputDecoration(
                    labelText: 'Set by',
                    border:
                        OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'width',
                      child: Text(
                        'Width',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'height',
                      child: Text(
                        'Height',
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setDialogState(() {
                      dimension = value;

                      controller.text =
                          value == 'width'
                              ? current.width
                                  .toStringAsFixed(
                                  2,
                                )
                              : current.height
                                  .toStringAsFixed(
                                  2,
                                );
                    });
                  },
                ),
                const SizedBox(
                  height: 12,
                ),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText:
                        'Target $unit',
                    border:
                        const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                  );
                },
                child: const Text(
                  'Cancel',
                ),
              ),
              FilledButton(
                onPressed: () {
                  final value =
                      double.tryParse(
                    controller.text,
                  );

                  if (value == null ||
                      value <= 0) {
                    return;
                  }

                  Navigator.pop(
                    dialogContext,
                    ExactSizeRequest(
                      dimension: dimension,
                      value: value,
                    ),
                  );
                },
                child: const Text(
                  'Apply',
                ),
              ),
            ],
          );
        },
      );
    },
  );

  controller.dispose();

  return result;
}
