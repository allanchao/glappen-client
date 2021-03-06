//import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:garderobel_api/garderobel_client.dart';
import 'package:garderobel_api/models/reservation.dart';
import 'package:garderobelappen/GlappenService.dart';
import 'package:garderobelappen/dashboard.dart';
import 'package:provider/provider.dart';

import 'locator.dart';

class Receipts extends StatelessWidget {
  const Receipts({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final api = locator.get<GarderobelClient>();
    final user = Provider.of<FirebaseUser>(context);
    final reservations = api.findReservationsForUser(user.uid);
    return StreamProvider.value(value: reservations, child: ReservationHandler());
  }
}

class NoReceipts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "empty title",
//              AppLocalizations.of(context).tr('dashboard.emptyState.title'),
            ),
            Text(
              "empty body",
//              AppLocalizations.of(context).tr('dashboard.emptyState.body'),
              textAlign: TextAlign.center,
            )
          ],
        )),
      ),
    );
  }
}

class ReservationPaymentAuthRequired extends StatelessWidget {
  final Reservation item;

  const ReservationPaymentAuthRequired({Key key, this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = locator.get<GlappenService>();

    return Container(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text("Awaithing authentication..."),
            RaisedButton(
              child: Text("Try again"),
              onPressed: () {},
            ),
            RaisedButton(
              child: Text("Cancel"),
              onPressed: () async {
                final response = await service.cancelCheckIn(item.docId);
                if (response != null) {
                  Scaffold.of(context).showSnackBar((SnackBar(
                    content: Text("Your reservation was successfully cancelled!"),
                  )));
                }
              },
            )
          ],
        ),
      ),
    );
  }
}

class ReservationPaymentMethodRequired extends StatelessWidget {
  final Reservation item;

  const ReservationPaymentMethodRequired({Key key, this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Text("Please select a different payment method"),
      ),
    );
  }
}

class ReservationHandler extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final list = Provider.of<Iterable<Reservation>>(context)?.toList() ?? [];
    final isAwaitingPayment = list.length > 0 && list[0].state.index < ReservationState.PAYMENT_RESERVED.index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ScanButtonState>(context).setState(!isAwaitingPayment);
    });

    if (list.length == 0) return NoReceipts();

    final item = list[0];
    if (isAwaitingPayment) {
      if (item.state == ReservationState.PAYMENT_AUTH_REQUIRED) {
        return ReservationPaymentAuthRequired(item: item);
      } else if (item.state == ReservationState.PAYMENT_METHOD_REQUIRED) {
        return ReservationPaymentMethodRequired(item: item);
      } else {
        return Container();
      }
    } else {
      return ReceiptsList();
    }
  }
}

class ReceiptsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    final list = Provider.of<Iterable<Reservation>>(context)?.toList() ?? [];
    return SafeArea(
      child: Container(
        margin: EdgeInsets.only(top: 60, bottom: 0),
        child: Swiper(
          itemBuilder: (context, i) => ReceiptItem(item: list[i]),
          itemCount: list?.length ?? 0,
          loop: false,
          viewportFraction: 0.8,
          scale: 0.93,
//          pagination: SwiperPagination(
//              builder: FractionPaginationBuilder(color: Colors.grey),
//              alignment: Alignment.topCenter),
        ),
      ),
    );
  }
}

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}

class ReceiptItem extends StatelessWidget {
  final Reservation item;

  const ReceiptItem({Key key, this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = locator.get<GlappenService>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 50, left: 5, right: 5, top: 40),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        color: HexColor('EFEAE6'),
        elevation: 12,
        child: Padding(
          padding: const EdgeInsets.only(top: 48, bottom: 16, left: 8, right: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                  flex: 3,
                  child: Container(
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: Center(
                            child: Text(item.hangerName, style: TextStyle(fontSize: 60, fontWeight: FontWeight.w900)),
                          ),
                        ),
                        Expanded(
                          child: Center(
                              child: Container(
                                  decoration: BoxDecoration(
                                      color: HexColor(item.color),
                                      borderRadius: BorderRadius.horizontal(
                                          right: Radius.circular(16), left: Radius.circular(16))),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                    child: Text(item.wardrobeName ?? "Wardrobe",
                                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  ))),
                          flex: 1,
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              item.venueName,
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      ],
                    ),
                  )),
              Expanded(
                flex: 2,
                child: Container(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
//                        Text(item.state.toString()),
                        _buildRaisedButton(context, item),
//                        buildAdminActionButton(service)
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAdminActionButton(GlappenService service) {
    if (item.state != ReservationState.PAYMENT_RESERVED && item.state != ReservationState.CHECKING_OUT)
      return Container();
    return RaisedButton(
      onPressed: () async {
        if (item.state == ReservationState.PAYMENT_RESERVED)
          service.confirmCheckIn(item.docId);
        else
          service.confirmCheckOut(item.docId);
      },
      child: Text('confirm'),
    );
  }

  void buildConfirmationButton(GlappenService service) {
    if (item.state == ReservationState.PAYMENT_RESERVED)
      service.confirmCheckIn(item.docId);
    else if (item.state == ReservationState.CHECKED_IN)
      // service.confirmCheckOut();
      null;
    else
      null;
  }

  RaisedButton _buildRaisedButton(BuildContext context, Reservation item) {
    final service = locator.get<GlappenService>();
    final textStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.bold);
    if (item.state == ReservationState.PAYMENT_RESERVED) {
      return RaisedButton(
        onPressed: () async {
          final result = await service.cancelCheckIn(item.docId);
          if (result != null) {
            Scaffold.of(context).showSnackBar(SnackBar(
              content: Text('Your reservation was successfully cancelled, and your payment has been refunded.'),
            ));
          }
        },
        child: Text('CANCEL', style: textStyle),
      );
    } else if (item.state == ReservationState.CHECKING_OUT) {
      return RaisedButton(
        onPressed: () async {
          final result = await service.cancelCheckOut(item.docId);
          Scaffold.of(context).showSnackBar(SnackBar(
            content: Text('Your request to check out has been cancelled.'),
          ));
        },
        child: Text(
          'CANCEL',
          style: textStyle,
        ),
      );
    } else {
      return RaisedButton(
        onPressed: () async {
          final response = await service.requestCheckOut(item.docId);
        },
        child: Text(
          'CHECK-OUT',
          style: textStyle,
        ),
      );
    }
  }
}
