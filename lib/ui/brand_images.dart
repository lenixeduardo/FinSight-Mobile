import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// PNGs recortados dos assets originais FinSight V5 fornecidos no projeto.
/// Redimensionados para resolução de avatar (52px) e quantizados, sem redesenho.
class FSBrandImage extends StatelessWidget {
  const FSBrandImage(this.ticker, {super.key, this.size = 32});
  final String ticker;
  final double size;

  static final Map<String, Uint8List> _raster = {
    'PETR4': base64Decode('iVBORw0KGgoAAAANSUhEUgAAADEAAAA0CAMAAAAUjyCdAAAAkFBMVEX7/Pv9xQYDh1EElFj75ZgCekfF59u249IumGr76aUSmmKs2siLyrDZ8un6vQM0pXRFpHtVtI398shMqoTT7OIUpGVotpUAdjl1w6OU0bn93XIAgT4IolxEnnYhk1l5vaGZ1sEAbjQAbkAkfVYgj11swJuBvaP+zCn8zkH90U3+8L4AAAAAAAAAAAAAAAAAAABRFsHfAAAAMHRSTlP/////////////////////////////////////////////////////////AAAAAABbeNiaAAAB+UlEQVR42u2T23LiMAyGsVwbJ45xQg5AKW33fHj/B1xJFsTewg656MxeVJMLzy9/1jGr1Ye9v22rB7aqksNbq6rtfL/6pf5pG/6U+lkJ8Kg2G3WfPSbg7vuC/FZLCJVCLCO2PxYBRKhFABPqg7i2T9cmOG/rzcWtZnv4b38/uxbLtMGz4vN7l1u2Bg1kzmbuxo3jqHUu+ahrNCTSfYBYRG7006hLyWsyiqETs+eL0/cXziVEJFjyTXNI6XVCnGOw6nawc4nQT3otEmh2TlAQeqAuwBGOLtAJnSNJwaHzyNE6IepEtKQdnp+1a+jUo7fjpLgrFC3UUNTB98JgLT3sCdAs2T3WEVKImSAkH8eqM+QsxuEnQ7mfCQ1u4MlZm0aA70GdT2NwO8PIhUg5f0Fx4vS+SmU4ah9SPUwAEiMTB1JfUDTATzsD33hAuBFpG9rPQgwcI7W+/WTMLg0aiYN0FAy3oL3EYCJy5OnUtxM/uAaTOorLJH08MXAmUhmZ9cbwINfcyIYnWRJNCWAnTS9loNdLnkJwGVnrg23IafarQGXQgF/xGGJJxK7v+xbt5ByWypsRYxtlWK1zUfaPN5HEtCqGTHY5DYwJ1uXHOxNaXKUVspxowWcfXEey830EXCVgEWHyNN+FwIUAc4sA0H93AYlX4BncIN407g9hvBxC1WHf9gAAAABJRU5ErkJggg=='),
    'VALE3': base64Decode('iVBORw0KGgoAAAANSUhEUgAAADMAAAA0CAMAAAAQevCgAAAAkFBMVEWtpiZtmJ8qlHhYbTttgTdkpVo3Wz1OcECWub6cvcHK3eACSln7/PwBUmIBm5kApKMCUF38wwYBoJ32vAcATWGqw8gBPE0BiYtIeYQBZW9Sg44BfINHdH4BcnsAnqCZmCyhvcMAsK4jY3DJqxji7e41XkU1ZU6NhSjLthnPtiXD1djU5ef/0AQcmXkjXmx2eTa0blq5AAAAMHRSTlP///////////////////////////////////////////////////////////////9Ppz/1AAAClUlEQVR42u2VaXPiMAyGDW33MrIV4yQbKNAC5W77///d+rbiAJ2d/bqCGY748StLssQmf2/sP/OPzPZUv9Q37MVYfdoWTD1b86Zp+E0zzz5GNWF+zTA9BG+I17DZOTI1mJX5GV5ZH21de6Z2mw+E6NK4i9n8ZJntR+PWFQwRJo+Br7eGGTX+T+wj5ESYGETgIzY5g5dJzgyZrGNXAZv8CDJwL3BJx34w55qGIgg2dHg1Co6ZNdHnwaZ9LKWATX5zKJOAeRX9Gn8ZncDAonU272BwDBewFKbIQKukMaWEkmJBYuy/ae2jAoTphHSIcCZbDIxzp+EPe8Y2hwP7xMyAWbgkkBIQGdBv+820cna57DPT2c2pkhBdiNRuVVVTZwaa7ohvbWSkIJBhHg+XiJjXThMGhoyBNK6qqGKp72Yp5rgtZMko1X1jlXUpIo8ugiSnbWBstJVDpFz5U1ROrFqFy+AYF0DIMVDB5JglaFptQqYc0/hkzF+ja1bCvtVSscCY8781lAllIl49YxWi5vsxOvfZcOJbZLqkI7Of46NHmM71yybPkdGLEDXKiCd6mHgXntP90W2PCSXx5A5zizFHWgoxyK5J0gO/ybi6S64tA/N+XPWvZY9BPpdJJlfEGDWWDMZug7YchK8GlSrc3AvQtK2m2gkMhMtHmM71JV4ymK/7IpWdv3yyDZksGHvVU4doaaRNc4BYMiVDGicse0zXWz5gQj11JGpybs7/FWPbqatwr9NC//gFg3mW2AoPCIc7DGbGead8ZrS+y4R/zCI99zpdU6bmBmN/+Aqf+66rae9HpEyWMYxtrO1geocZaWZWnwkzrxM+mVpfY37SCazTlATbEo0gL8a38+28pqN8OFgLHTNP/gDdKo/S7eWKkgAAAABJRU5ErkJggg=='),
    'ITUB4': base64Decode('iVBORw0KGgoAAAANSUhEUgAAADAAAAA0CAMAAAD7TUujAAAAkFBMVEX8VwT9/Pr7SgH9Yg/8aSr8djT+59f9iE/+28j+1bn9yKf9mWn97eH9pXb+kln7e0T8to/8q4P8OQD9w5r7XyX88N8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADyA+NGAAAAMHRSTlP/////////////////////////////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAASrF2HAAAB1klEQVR42u2V2a7cIAxAjY3ZySSZ9v9/tTZZ70ymN1Sq1If6ISKYgzfAYDoF/gP/FBCqZ7afhXM8A8EDggouArvgIRx3IOEM3wvCuALpvOVvkbEBDm6uFwkKZLxLEHgBHNwXoghmxA4AMqhHHRYYzKPLJQLDYqjDJ7XwNwH4M+CuMyvAN9NDLwB+k004ANyO/aq5WA+Wd9UCwBTq5/1xKCZtJowVAFmuhVTQT6O9ICbRZlhNLABFE/Xwmp9vhSeY2h2mNfAGSMi82Anwfrc5Mx2pKg2gnD142arU6nXNUGt+KOFz1tXsPZ2Atrd164sD9FxGyaJOijt6/wc4WVCA2jPiSkJrTExJCbBBs9Gu/yvggB7OOPtDJr1HnB9F/mgF6g64HSC1H1vJcdaHIRjHJC5Jpa4BaEDLS43BFZljuAWwhh+TunQCPBK8AmEBJEla8ajAEYNfyuKOLCkQpGay0ti5xdAAPyOmS0C0ZcwZRPtkL19R6jfr+A2QFxCnVi87bN3DMfp19AJQck89UVMI4UlQRR+9d0lrEl0JA6fIZ2BvH9sRZas/y7+1cDqKJ0CnvvSfL31jGxd7pafPT0+x0CfdQN9jrEBPf5CMgVySDkHpQKYriPgLYtIPe9EXV/EAAAAASUVORK5CYII='),
    'MGLU3': base64Decode('iVBORw0KGgoAAAANSUhEUgAAADEAAAA0CAMAAAAUjyCdAAAAkFBMVEUBfPv5+/0Egfwxk/lOpfyz3P3M6P1wuvrb8v274f2MyfwtjvdCmPt4wfkakP02o/ua0f0Abvlasf9srvwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAfwbrAAAAMHRSTlP//////////////////////////wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABPNGsBAAABhklEQVR42u2V2XKFIAyGf8Im2LO17/+uVQi7Hg+3nWacUSEfCUkIELOCf+KPEIu26q3Y59IQXoKFiHAsd7tkwsigeSGAdEw4AqGdKwb3v/QC6UAs6zhZI2WQcF92wsa58FwIQW2EuVasGQfhpwB8Q9jXhP62E4gvTBGAkFMEzRGoCPrcTEMo54wzzxqXXmunb9QTnFPNZVktaeKQTF5EIpcTE0LxPMGLjkBDUCI0VxOkuCBcUrBol9iSdkGY6KUSV4TJGh7tf0fkA1g0hNxMWDFDeKK7qYmDfCRiiYoPjqypCBqIsHPnubvEQNuRqE55CKZ5hGVNjKyynA8uwyNioZ/iv8btA0KibFkeEXIkVJV7W6qE+p0jE6kA99TbIxs0EGuuYSbWC4Ki9xo58YmgUyIkU80QIMlH5HQf6IjcOjoCBzYMnRIYCNMSYfA2doY1XzccocrG9hWqzNEJwbao6ZrtWBMrKsuUab6cqOtX6O+/5lpDFacu56ORrFo7sNdnNv62p/PXL14pDQGS6FiFAAAAAElFTkSuQmCC'),
  };

  @override
  Widget build(BuildContext context) {
    final png = _raster[ticker];
    if (png == null) {
      return SizedBox(width: size, height: size,
        child: Center(child: Text(ticker.substring(0, ticker.length > 2 ? 2 : ticker.length),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))));
    }
    return SizedBox(
      width: size, height: size,
      child: Image.memory(png, width: size, height: size, fit: BoxFit.contain,
        filterQuality: FilterQuality.medium, gaplessPlayback: true,
        semanticLabel: 'Logotipo $ticker'),
    );
  }
}
