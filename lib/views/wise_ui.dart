import 'dart:math';

import 'package:flutter/material.dart';
import 'package:show_app/constants/constants.dart';
import 'package:show_app/models/rates.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WiseUi extends StatefulWidget {
  const WiseUi({super.key});

  @override
  State<WiseUi> createState() => _WiseUiState();
}

class _WiseUiState extends State<WiseUi> {
  List<Rate> rates = [];
  String? selectedDevice;

  int? selectedService;

  double? averageRateXOF;
  double? averageRateEUR;

  String _value = "0";
  double solde = 0;
  double soldeByService = 0;

  Future<void> fetchRates() async {
    final response = await http.get(Uri.parse(URL), headers: {
      "Content-Type": "application/json",
    });
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      final rateObjects = jsonData.map((item) => Rate.fromJson(item)).toList();

      double totalRateXOF = 0;
      double totalRateEUR = 0;
      int countXOF = 0;
      int countEUR = 0;

      for (var rate in rateObjects) {
        for (var r in rate.rates) {
          if (r['currency_to'] == 'XOF') {
            totalRateXOF += r['exchange_rate'];
            countXOF++;
          } else if (r['currency_to'] == 'EUR') {
            totalRateEUR += r['exchange_rate'];
            countEUR++;
          }
        }
      }

      setState(() {
        rates = rateObjects;
        averageRateXOF = countXOF > 0 ? totalRateXOF / countXOF : null;
        averageRateEUR = countEUR > 0 ? totalRateEUR / countEUR : null;
      });
    } else {
      print("Erreur lors de la récupération des taux : ${response.statusCode}");
    }
  }

  makeConversion() {
    if (selectedDevice != null) {
      switch (selectedDevice) {
        case "XOF":
          solde = double.parse(_value) * averageRateXOF!;
          if (selectedService != null) {
            soldeByService = double.parse(_value) *
                rates[selectedService!].rates[0]['exchange_rate'];
          }
          break;
        case "EUR":
          solde = double.parse(_value) * averageRateEUR!;
          if (selectedService != null) {
            soldeByService = double.parse(_value) *
                rates[selectedService!].rates[1]['exchange_rate'];
          }
          break;
        default:
      }
    }
  }

  Color _getRandomColor() {
    final random = Random();
    return Color.fromARGB(
      255, // Opacité maximale
      random.nextInt(256), // Rouge (0-255)
      random.nextInt(256), // Vert (0-255)
      random.nextInt(256), // Bleu (0-255)
    );
  }

  @override
  void initState() {
    super.initState();
    fetchRates();
  }

  @override
  Widget build(BuildContext context) {
    List<String> availableCurrencies = rates
        .expand((rate) => rate.rates.map((r) => r['currency_to'] as String))
        .toSet()
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      appBar: AppBar(
        title: const Text("Taux de change"),
        backgroundColor: Colors.blue,
        actions: [
          ElevatedButton(onPressed: () {}, child: const Text("S'inscrire"))
        ],
        leading: const Icon(Icons.menu),
      ),
      body: SingleChildScrollView(
          child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(10),
            width: MediaQuery.of(context).size.width - 40,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25), color: Colors.white),
            child: Column(
              children: [
                const Text("Vous voyagez a l'etranger ?"),
                TextButton(
                  child: const Text(
                    "Comparer les options pour optimiser\nvotre argent en voyage",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  onPressed: () {},
                ),
                if (averageRateXOF != null && averageRateEUR != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      "Taux de change moyen du CAD :\nXOF: ${averageRateXOF!.toStringAsFixed(2)}, EUR: ${averageRateEUR!.toStringAsFixed(2)}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25), color: Colors.white),
            child: Column(
              children: [
                SizedBox(
                    //width: 150,
                    child: TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Montant en CAD',
                      suffixText: "CAD"),
                  onChanged: (value) {
                    setState(() {
                      _value = value;
                      makeConversion();
                    });
                  },
                )),
                const SizedBox(
                  height: 25,
                ),
                Container(
                  alignment: Alignment.center,
                  width: MediaQuery.of(context).size.width - 60,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: DropdownButton<String>(
                    hint: const Text('convertir en'),
                    style: const TextStyle(fontSize: 20, color: Colors.black),
                    value: selectedDevice,
                    items: availableCurrencies.map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDevice = value;
                        makeConversion();
                      });
                    },
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                if (selectedDevice != null)
                  ListTile(
                    title: const Text(
                      "Vous envoyez en moyenne",
                    ),
                    subtitle: Text(
                      "$solde",
                      style: const TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 35,
                          fontWeight: FontWeight.bold),
                    ),
                    trailing: Text("$selectedDevice"),
                  ),
                const Divider(),
                (selectedService != null && selectedDevice != null)
                    ? (ListTile(
                        leading: const Text("et"),
                        title: Text(
                          "$soldeByService",
                          style:
                              const TextStyle(color: Colors.blue, fontSize: 25),
                        ),
                        subtitle:
                            Text(" sur ${rates[selectedService!].company}"),
                        trailing: Text("$selectedDevice"),
                      ))
                    : (const Text(
                        "Vous pouvez choisir un service pour voir sa convertion",
                        textAlign: TextAlign.center,
                      )),
                const Divider(),
                ListView.builder(
                    itemCount: rates.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final rate = rates[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                                backgroundColor: _getRandomColor()),
                            title: Text(
                              rate.company,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: rate.rates.map((r) {
                                return Text(
                                    "${r['currency_to']}: ${r['exchange_rate']}");
                              }).toList(),
                            ),
                            trailing: (selectedService == index)
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                selectedService = index;
                                makeConversion();
                              });
                            },
                          ),
                          const Divider()
                        ],
                      );
                      /*return Card(
                          color: (selectedService == index)
                              ? Colors.lightBlueAccent
                              : null,
                          child: ListTile(
                            title: Text(rate.company),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: rate.rates.map((r) {
                                return Text(
                                    "${r['currency_to']}: ${r['exchange_rate']}");
                              }).toList(),
                            ),
                            onTap: () {
                              setState(() {
                                selectedService = index;
                                makeConversion();
                              });
                            },
                          ));*/
                    })
              ],
            ),
          )
        ],
      )),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: fetchRates,
        tooltip: 'Refresh',
        icon: const Icon(Icons.refresh),
        label: const Text('Rafraichir'),
      ),
    );
  }
}
