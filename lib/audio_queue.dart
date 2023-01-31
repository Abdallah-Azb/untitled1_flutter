import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';
import 'package:async_locks/async_locks.dart';
import 'package:byte_util/byte.dart';
import 'package:collection/collection.dart';

class AudioQueue {
  static const List<int> u2l = [
    -32124, -31100, -30076, -29052, -28028, -27004, -25980, -24956, -23932, -22908, -21884, -20860, -19836, -18812, -17788, -16764, -15996, -15484, -14972, -14460,
    -13948, -13436, -12924, -12412, -11900, -11388, -10876, -10364, -9852, -9340, -8828, -8316, -7932, -7676, -7420, -7164, -6908, -6652, -6396, -6140, -5884, -5628, -5372, -5116, -4860, -4604,
    -4348, -4092, -3900, -3772, -3644, -3516, -3388, -3260, -3132, -3004, -2876, -2748, -2620, -2492, -2364, -2236, -2108,
    -1980, -1884, -1820, -1756, -1692, -1628, -1564, -1500, -1436, -1372, -1308, -1244, -1180, -1116, -1052, -988, -924, -876, -844, -812, -780, -748, -716, -684, -652, -620, -588, -556, -524,
    -492, -460, -428, -396, -372, -356, -340, -324, -308, -292, -276, -260, -244, -228, -212, -196, -180, -164, -148, -132, -120, -112, -104, -96, -88, -80, -72, -64, -56, -48, -40, -32, -24, -16,
    -8, 0, 32124, 31100, 30076, 29052, 28028, 27004, 25980, 24956, 23932, 22908, 21884, 20860, 19836, 18812, 17788,
    16764, 15996, 15484, 14972, 14460, 13948, 13436, 12924, 12412, 11900, 11388, 10876, 10364, 9852, 9340, 8828, 8316, 7932, 7676, 7420, 7164, 6908, 6652, 6396, 6140, 5884, 5628, 5372, 5116, 4860,
    4604, 4348, 4092, 3900, 3772, 3644, 3516, 3388, 3260, 3132, 3004, 2876, 2748, 2620, 2492, 2364, 2236, 2108, 1980, 1884, 1820, 1756, 1692, 1628, 1564, 1500, 1436, 1372, 1308, 1244, 1180, 1116,
    1052, 988, 924, 876, 844, 812, 780, 748, 716, 684, 652, 620, 588, 556, 524, 492, 460, 428, 396, 372, 356, 340,
    324, 308, 292, 276, 260, 244, 228, 212, 196, 180, 164, 148, 132, 120, 112, 104, 96, 88, 80, 72, 64, 56, 48, 40, 32, 24, 16, 8, 0
  ];

  static List<int> l2uexp = [
    0, 0, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
  ];


  static final Uint8List l2u = generateL2u();

  final _semaphore =Semaphore(1);
  PriorityQueue<Frame> buffer = PriorityQueue<Frame>();
  Queue<Frame> decodeQueue = ListQueue<Frame>();
  int audioCount = 0;
  int lastAudioSeq = 0;
  int lastDelivered = 0;

  Future<void> reset()  async {

    await _semaphore.acquire().then((value) {
      buffer.clear();
      decodeQueue.clear();
      audioCount = 0;
      lastAudioSeq = 0;
      _semaphore.release();
    });
  }

  Future<void> enqueue(int seq, Int8List ulaw, int r)  async {

    if (seq < 50 * 5 && lastDelivered > seq + 5 * 50) {
      // assume reset
      lastDelivered = 0;
    }


    if (seq < lastDelivered) {
      return;
    }

    final Frame f = Frame(seq, ulaw, r);
    if (buffer.contains(f)) {
      // print("I'm returning");
      return;
    }


    buffer.add(f);
    while (buffer.isNotEmpty && buffer.first.seq == lastDelivered + 1 || buffer.length > 30) {
      audioCount++;
      final Frame sf = buffer.removeFirst();
      lastDelivered = sf.seq;

      await _semaphore.acquire().then((value) {
        decodeQueue.addLast(sf);
        _semaphore.release();
      });

    }
  }

  Future<void> startDecoding(AudioListener audioListener) async {
   await reset();
    Future.microtask(() async {
      try {
        while (true) {
          Frame ulawFrame;
          await _semaphore.acquire();
          if (decodeQueue.isEmpty) {
            _semaphore.release();
            // continue;
              await Future.delayed(const Duration(seconds: 2));
          }
          else {
            ulawFrame = decodeQueue.removeFirst();
            _semaphore.release();
            int ulawLength = ulawFrame.ulaw.length;
            int downsampling = 1;
            List<int> pcm = List<int>.filled(ulawLength + ulawLength % downsampling , 0, growable: false);
            int gainFactor = 1;
            for (int p = 0, u = 0; p < pcm.length; p++, u += downsampling) {
              int e = (u2l[ulawFrame.ulaw[min(u, ulawLength - 1)] & 0xff] * gainFactor);
              if (e > 0x7fff) {
                e = 0x7fff;
              } else if (e < -0x7fff) {
                e = -0x7fff;
              }
              pcm[p] = e;
            }
            // print("AudioAfter , ${pcm}");
            audioListener.onAudioReceived(pcm);
            _semaphore.release();
          }

        }
      } catch (e) {
        print(e);
      }
    });
  }

  // void startDecoding(AudioListener audioListener) {
  //   reset();
  //
  //
  //     Future.microtask(() {
  //
  //     });
  //
  //   // try{
  //   //   Timer.periodic(const Duration(microseconds: 10), (timer) {
  //   //
  //   //     Frame? ulawFrame;
  //   //     decodeQueue.synchronized(() async {
  //   //       if (decodeQueue.isEmpty) {
  //   //
  //   //         Future.delayed(const Duration(seconds: 3), () {});
  //   //       }
  //   //       try{
  //   //         ulawFrame = decodeQueue.removeFirst();
  //   //       }
  //   //       catch(e){
  //   //
  //   //       }
  //   //
  //   //     });
  //   //
  //   //     int ulawLength = ulawFrame!.ulaw.length;
  //   //     int downsampling = 1;
  //   //     List<int> pcm = [];
  //   //
  //   //     int gainFactor = 1;
  //   //     for (int p = 0, u = 0; p < pcm.length; p++, u += downsampling) {
  //   //       int e = (u2l[ulawFrame!.ulaw[min(u, ulawLength - 1)] & 0xff] *
  //   //           gainFactor);
  //   //
  //   //       if (e > 0x7fff) {
  //   //         e = 0x7fff;
  //   //       } else if (e < -0x7fff) {
  //   //         e = -0x7fff;
  //   //       }
  //   //       pcm[p] = e;
  //   //     }
  //   //     audioListener.onAudioReceived(pcm);
  //   //
  //   //   }) ;
  //   // }catch(e){
  //   //   print("ExceptionIs${e}");
  //   // }
  //
  //
  //
  // }


  static Uint8List generateL2u() {
    Uint8List result = Uint8List(64 * 1024);
    for (int i = 0; i < result.length; i++) {
      result[i] = l2uByte(i).value;
    }
    return result;
  }

  static Byte l2uByte(int sample) {
    const int cBias = 0x84;
    const int cClip = 32635;
    int sign = ((~sample) >> 8) & 0x80;
    if (sign == 0) {
      sample = -sample;
    }
    if (sample > cClip) {
      sample = cClip;
    }
    sample = sample + cBias;
    int exponent = l2uexp[(sample >> 7) & 0xff];
    int mantissa = (sample >> (exponent + 3)) & 0x0f;
    int compressedByte = ~(sign | (exponent << 4) | mantissa);
    return Byte(compressedByte);
  }


}

abstract class AudioListener {
  void onAudioReceived(List<int> audio);
}

class Frame implements Comparable<Frame> {
  final int seq;
  final Int8List ulaw;
  final int r;

  Frame(this.seq, this.ulaw, this.r);

  @override
  int compareTo(Frame other) {
    return seq - other.seq;
  }

  @override
  int get hashCode => seq;

  @override
  bool operator ==(Object other) {
    return other is Frame && other.seq == seq;
  }
}
