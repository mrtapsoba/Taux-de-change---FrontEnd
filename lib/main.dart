import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:show_app/constants/constants.dart';
import 'dart:convert';

import 'package:show_app/models/rates.dart';
import 'package:show_app/views/wise_ui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Taux de change',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const WiseUi() //MyHomePage(title: 'Taux de Change'),
        );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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

    /*if (!availableCurrencies.contains('CAD')) {
      availableCurrencies.add('CAD');
    }*/

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          ElevatedButton.icon(
              onPressed: fetchRates,
              icon: const Icon(Icons.refresh),
              label: const Text(
                "Rafraichir",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              )),
          const SizedBox(
            width: 20,
          )
        ],
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            if (averageRateXOF != null && averageRateEUR != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  "Taux de change moyen du CAD :\nXOF: ${averageRateXOF!.toStringAsFixed(2)}, EUR: ${averageRateEUR!.toStringAsFixed(2)}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            Container(
              margin: const EdgeInsets.all(15),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Theme.of(context)
                      .colorScheme
                      .inversePrimary
                      .withOpacity(0.5)),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SizedBox(
                        width: 150,
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
                    Container(
                      width: 150,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: DropdownButton<String>(
                        hint: const Text('convertir en'),
                        style:
                            const TextStyle(fontSize: 20, color: Colors.black),
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
                  ],
                ),
                if (selectedDevice != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      "donne $solde $selectedDevice en moyenne",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                (selectedService != null && selectedDevice != null)
                    ? (Container(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          "$soldeByService $selectedDevice sur ${rates[selectedService!].company}",
                          style: const TextStyle(fontSize: 20),
                        ),
                      ))
                    : (const Text(
                        "Vous pouvez choisir un service pour voir sa convertion"))
              ]),
            ),
            Expanded(
                child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 15),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Theme.of(context)
                      .colorScheme
                      .inversePrimary
                      .withOpacity(0.5)),
              child: ListView.builder(
                itemCount: rates.length,
                itemBuilder: (context, index) {
                  final rate = rates[index];
                  return Card(
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
                      ));
                },
              ),
            ))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: fetchRates,
        tooltip: 'Refresh',
        icon: const Icon(Icons.refresh),
        label: const Text('Rafraichir'),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
