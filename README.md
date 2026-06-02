# amalgame-hal

Portable **Hardware Abstraction Layer** for Amalgame — a tiny set of
backend-neutral interfaces that high-level component drivers
(`amalgame-hardware-led` / `-motor` / `-sensor` / `-display`) program
against, so each driver is **written once** and runs on any backend:

- **`amalgame-hardware-gpio`** → Raspberry Pi / Linux SBCs (today)
- a future **`Amalgame.Mcu`** backend → bare-metal MCUs (later)

```sh
amc package add hal
```

## Interfaces

| Interface | Methods |
|---|---|
| `DigitalOut` | `Write(level)`, `High()`, `Low()`, `Toggle()` |
| `DigitalIn`  | `Read() -> int` (0/1) |
| `PwmOut`     | `SetFrequency(hz, dutyPercent)`, `SetPeriod(ns)`, `SetDuty(ns)`, `Enable()`, `Disable()` |
| `I2cBus`     | `WriteByte/ReadByte/WriteReg/ReadReg/WriteBytes/ReadBytes(addr, …)` |
| `SpiBus`     | `Transfer(List<int>) -> List<int>` |
| `Clock`      | `DelayMs(ms)`, `DelayUs(us)`, `Millis()`, `Micros()` |

Types are deliberately primitive (`int` / `bool` / `List<int>`) so the
contract carries nothing Linux- or MCU-specific. Levels are plain ints
(0 = low, non-zero = high).

## How drivers use it

```amalgame
// in a driver package — depends only on amalgame-hal
public class Servo {
    private pwm: PwmOut
    public Servo(pwm: PwmOut) { this.pwm = pwm; let _ = this.pwm.SetPeriod(20000000) }
    public void Write(angle: int) { /* … this.pwm.SetDuty(…) … */ }
}
```

```amalgame
// on a Raspberry Pi — hand the driver the Pi backend's class
import Amalgame.Hardware          // Pwm implements PwmOut
import Amalgame.Hardware.Motor
let s = new Servo(new Pwm(0, 0))  // same driver, any backend
```

Requires **amc ≥ 0.8.72** (working cross-package interface dispatch).

## License
Apache-2.0 — see [LICENSE](LICENSE). Pure Amalgame, no C.
