import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';

import 'package:lidl_lite/qrcodegen.dart';

class CardContainer extends StatelessWidget {
  final String code;
  final String name;

  CardContainer(this.code, this.name);

  @override
  Widget build(BuildContext context) {
    var qrCode = QrCode.encodeText(code, QrCodeEcc.LOW).toSvgString(0);

    var cardWidth = (MediaQuery.of(context).size.width - 20);
    var cardHeight = cardWidth * 0.7;
    var cardPadding = 15;
    var qrPadding = (cardHeight - (cardPadding * 2) - 120) / 2;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(15))
      ),
      width: cardWidth,
      height: cardHeight,
      margin: EdgeInsets.only(top: 20),
      padding: EdgeInsets.all(cardPadding.toDouble()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: qrPadding),
            child: Center(
              child: SvgPicture.string(
                qrCode,
                width: 120.0,
                height: 120.0
              ),
            )
          ),
          Spacer(),
          Padding(
            padding: EdgeInsets.only(bottom: 5),
            child: Text(
              name,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14.0,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          Text(
            code.substring(0, 17),
            style: TextStyle(
              color: Colors.black38,
              fontSize: 10.0,
            ),
            textAlign: TextAlign.left,
          ),
        ]
      )
    );
  }
}
