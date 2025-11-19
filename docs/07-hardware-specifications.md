# Hardware Specifications

This document details all hardware components for prototype and production devices.

---

## Product Line Overview

| Specification | Core Model | Pro Model |
|---------------|------------|-----------|
| **Retail Price** | $129 | $299 |
| **Manufacturing Cost** | $40 | $175 |
| **Target Margin** | 69% | 42% |
| **Video Resolution** | 720p @ 30fps | 4K @ 30fps |
| **Storage** | 32GB eMMC (24hrs) | 512GB eMMC (72hrs) |
| **AI Processing** | Cloud-based (subscription) | On-device (NPU) |
| **Battery** | 500-1000mAh (backup) | 7000mAh (8-10hrs) |
| **Sensors** | Temperature + Humidity | Full suite |

---

## Prototype Hardware (Raspberry Pi 4)

### Development Platform

**Purpose:** Proof of concept, software development, testing

| Component | Specification | Cost | Source |
|-----------|---------------|------|--------|
| **Raspberry Pi 4** | 8GB RAM (already owned) | $75 | RaspberryPi.com |
| **Camera** | Camera Module 3 (12MP, 1080p) | $25 | RaspberryPi.com |
| **Power Supply** | Official USB-C 5V/3A | $10 | RaspberryPi.com |
| **Storage** | 128GB microSD (A2, UHS-I) | $15 | Amazon |
| **Case** | Official case (optional) | $12 | RaspberryPi.com |

**Total:** $137 (or $62 if Pi already owned)

### Environmental Sensors

| Sensor | Purpose | Interface | Cost | Part Number |
|--------|---------|-----------|------|-------------|
| **BME680** | Temp, humidity, pressure, air quality | I2C | $20 | Adafruit 3660 |
| **BH1750** | Ambient light level | I2C | $8 | Generic |
| **ADXL345** | Motion/vibration detection | I2C | $10 | Adafruit 1231 |

**Total Sensors:** $38

### Audio Components

| Component | Specification | Cost | Source |
|-----------|---------------|------|--------|
| **USB Audio Adapter** | With microphone input | $15 | Amazon |
| **Speaker** | 3-5W, 8Ω | $10 | Amazon |

**Total Audio:** $25

### Prototyping Supplies

| Item | Purpose | Cost |
|------|---------|------|
| Half-size breadboard | Sensor connections | $5 |
| Jumper wires (40pc M-F) | Wiring | $5 |
| USB cables | Power, connections | $5 |

**Total Supplies:** $15

### Complete Prototype Cost

**Grand Total:** $215 (or $100 if Pi already owned)

**Capacity:** Supports 1-50 test users comfortably

---

## Production Hardware - Core Model

### System-on-Chip (SoC)

**Recommended:** Rockchip RV1126

| Specification | Value |
|---------------|-------|
| **CPU** | Quad-core ARM Cortex-A7 @ 1.5GHz |
| **NPU** | 1.2 TOPS (for basic AI) |
| **ISP** | Built-in Image Signal Processor |
| **Video Encoder** | H.264/H.265, up to 1080p @ 60fps |
| **RAM** | 1GB DDR3L (integrated) |
| **Package** | Small form factor, low power |
| **Cost** | $10-12 per chip (volume) |

**Why RV1126:**
- Purpose-built for IP cameras
- Hardware video encoding (low power)
- Adequate NPU for basic person detection
- Mature SDK and documentation
- Used in many commercial IP cameras

**Alternative:** Rockchip RK3566 (more powerful, $15-20)

### Camera Module

| Specification | Value |
|---------------|-------|
| **Sensor** | Sony IMX335 or similar |
| **Resolution** | 5MP (supports 720p, 1080p) |
| **Frame Rate** | 30fps @ 1080p |
| **Interface** | MIPI CSI |
| **Low Light** | Good sensitivity (0.01 lux) |
| **IR Support** | IR-cut filter switchable |
| **Cost** | $8-12 |

### IR LEDs (Night Vision)

| Specification | Value |
|---------------|-------|
| **Type** | 850nm infrared LEDs (invisible) |
| **Count** | 4-6 LEDs |
| **Range** | 3-5 meters |
| **Cost** | $2-3 |

### Storage

| Specification | Value |
|---------------|-------|
| **Type** | eMMC 5.1 |
| **Capacity** | 32GB |
| **Speed** | HS400 (200 MB/s) |
| **Cost** | $5-7 |

**Retention:** 24 hours of 720p @ 3Mbps = ~13GB

### Sensors

| Sensor | IC | Purpose | Cost |
|--------|-----|---------|------|
| **Temp/Humidity** | Si7021 or SHT31 | Basic environmental monitoring | $3-5 |

**Note:** Core model has minimal sensors to keep cost down

### Audio

| Component | Specification | Cost |
|-----------|---------------|------|
| **Microphone** | MEMS, omnidirectional, 60dB SNR | $1-2 |
| **Speaker** | 2W, 8Ω, 30mm diameter | $2-3 |
| **Audio Codec** | Basic codec (often integrated in SoC) | $0-2 |

### Battery

| Specification | Value |
|---------------|-------|
| **Capacity** | 500-1000mAh |
| **Type** | Li-ion rechargeable |
| **Purpose** | Shutdown protection (5-10 minutes) |
| **Connector** | Magnetic (easy replacement) |
| **Cost** | $3-5 |

**Note:** Core model is primarily AC-powered, battery for graceful shutdown only

### Connectivity

| Component | Specification | Cost |
|-----------|---------------|------|
| **WiFi/BT Module** | 2.4GHz WiFi + BT 5.0 (often integrated or $3-5 module) | $0-5 |
| **Antenna** | PCB antenna or external | $1-2 |

### Power Management

| Component | Purpose | Cost |
|-----------|---------|------|
| **PMIC** | Power management IC | $2-3 |
| **USB-C Port** | PD (Power Delivery) support | $1-2 |
| **Regulators** | 3.3V, 1.8V, 1.2V rails | $2-3 |

### Housing & Mechanical

| Component | Specification | Cost |
|-----------|---------------|------|
| **Enclosure** | Injection molded plastic | $4-6 (at volume) |
| **Lens** | Glass or acrylic, anti-scratch | $2-3 |
| **Mounting** | Wall mount bracket | $1-2 |
| **Screws/Hardware** | Assembly hardware | $0.50 |

### PCB

| Specification | Value |
|---------------|-------|
| **Layers** | 4-layer |
| **Size** | ~60mm x 60mm |
| **Cost** | $3-5 per board (volume) |

### Bill of Materials (Core Model)

| Category | Cost |
|----------|------|
| SoC (RV1126) | $12 |
| Camera module | $10 |
| IR LEDs | $2.50 |
| Storage (32GB eMMC) | $6 |
| Temp/Humidity sensor | $4 |
| Microphone | $1.50 |
| Speaker | $2.50 |
| Audio codec | $1 |
| Battery (500mAh) | $4 |
| WiFi/BT | $3 |
| PMIC & regulators | $5 |
| USB-C port | $1.50 |
| PCB | $4 |
| Enclosure | $5 |
| Lens | $2.50 |
| Mounting hardware | $2 |
| Assembly labor | $8 |
| **Total** | **$75** |

**Target:** $40 per unit at 1,000+ volume
**Gap:** Need to optimize ($35 savings needed)
**Options:**
- Cheaper camera module ($6 instead of $10) = $4 saved
- Smaller battery (500mAh instead of 1000mAh) = $2 saved
- Negotiate volume pricing = $10-15 saved
- Alternative SoC or integrated components = $5-10 saved

**Revised realistic cost:** $40-50 at 1,000+ units

---

## Production Hardware - Pro Model

### System-on-Chip (SoC)

**Recommended:** Rockchip RK3588

| Specification | Value |
|---------------|-------|
| **CPU** | Quad-core Cortex-A76 + Quad-core Cortex-A55 |
| **NPU** | 6 TOPS (dedicated AI processing) |
| **ISP** | Advanced ISP, supports 8K |
| **Video Encoder** | H.264/H.265, up to 8K @ 30fps or 4K @ 120fps |
| **RAM** | 4GB LPDDR4 (or 8GB) |
| **Package** | BGA, requires proper thermal management |
| **Cost** | $50-60 per chip (volume) |

**Why RK3588:**
- Powerful NPU for on-device AI
- 4K video encoding with low power
- Well-documented SDK
- Used in many SBCs (Orange Pi 5, Rock 5)

**Alternative:** NXP i.MX 8M Plus ($35-50, 2.3 TOPS NPU, better supply chain)

### Camera Module

| Specification | Value |
|---------------|-------|
| **Sensor** | Sony IMX415 or IMX585 |
| **Resolution** | 8MP (supports 4K) |
| **Frame Rate** | 30fps @ 4K |
| **Interface** | MIPI CSI-2 (4-lane) |
| **Low Light** | Excellent (0.005 lux, Starvis technology) |
| **IR Support** | IR-cut filter switchable |
| **Cost** | $25-35 |

### IR LEDs (Night Vision)

| Specification | Value |
|---------------|-------|
| **Type** | 940nm infrared LEDs (completely invisible) |
| **Count** | 8-10 LEDs |
| **Range** | 5-8 meters |
| **Cost** | $4-6 |

### Storage

| Specification | Value |
|---------------|-------|
| **Type** | eMMC 5.1 |
| **Capacity** | 512GB |
| **Speed** | HS400 (400 MB/s) |
| **Cost** | $50-60 |

**Retention:** 72 hours of 4K @ variable bitrate (avg 10Mbps) = ~324GB

### Sensors (Full Suite)

| Sensor | IC | Purpose | Interface | Cost |
|--------|-----|---------|-----------|------|
| **Temp/Humidity/Pressure/Air Quality** | BME680 | Comprehensive environmental | I2C | $8-10 |
| **Light** | BH1750 or TSL2591 | Ambient light monitoring | I2C | $3-5 |
| **Vibration** | ADXL345 or LIS3DH | Motion/vibration detection | I2C | $3-5 |

**Total Sensors:** $14-20

### Audio

| Component | Specification | Cost |
|-----------|---------------|------|
| **Microphone Array** | 2x MEMS mics for beamforming | $4-6 |
| **Speaker** | 5W, 8Ω, high-quality | $5-8 |
| **Audio Codec** | High-quality codec (ES8316 or similar) | $3-5 |

**Total Audio:** $12-19

### Battery

| Specification | Value |
|---------------|-------|
| **Capacity** | 7000mAh |
| **Type** | Li-ion rechargeable |
| **Runtime** | 8-10 hours (4K streaming + AI) |
| **Connector** | Magnetic (easy replacement) |
| **Protection** | Over-charge, over-discharge, short-circuit |
| **Cost** | $15-20 |

### Connectivity

| Component | Specification | Cost |
|-----------|---------------|------|
| **WiFi 6 + BT 5.2** | Dual-band 2.4/5GHz WiFi + Bluetooth 5.2 | $8-12 |
| **Thread/Matter** (optional) | For smart home integration | $3-5 |
| **Antennas** | Dual antennas (WiFi diversity) | $2-3 |

### Power Management

| Component | Purpose | Cost |
|-----------|---------|------|
| **Advanced PMIC** | RK809 or similar | $5-7 |
| **USB-C PD Controller** | 27W+ power delivery | $2-3 |
| **Regulators** | Multiple voltage rails | $4-6 |
| **Charging IC** | Fast charging for 7000mAh battery | $2-3 |

### Cooling

| Component | Purpose | Cost |
|-----------|---------|------|
| **Heatsink** | Passive cooling for RK3588 | $2-3 |
| **Thermal Pad** | Thermal interface material | $0.50 |
| **Optional Fan** | Active cooling if needed | $3-5 (if required) |

### Housing & Mechanical

| Component | Specification | Cost |
|-----------|---------------|------|
| **Premium Enclosure** | Injection molded, soft-touch finish | $10-15 |
| **Glass Lens** | Scratch-resistant glass | $4-6 |
| **Mounting System** | Articulating mount, wall/ceiling | $5-8 |
| **Screws/Hardware** | Assembly hardware | $1-2 |

### PCB

| Specification | Value |
|---------------|-------|
| **Layers** | 6-layer (for proper signal integrity) |
| **Size** | ~80mm x 80mm |
| **Cost** | $8-12 per board (volume) |

### Bill of Materials (Pro Model)

| Category | Cost |
|----------|------|
| SoC (RK3588) | $55 |
| Camera module (4K) | $30 |
| IR LEDs | $5 |
| Storage (512GB eMMC) | $55 |
| Sensors (full suite) | $17 |
| Microphone array | $5 |
| Premium speaker | $7 |
| Audio codec | $4 |
| Battery (7000mAh) | $18 |
| WiFi 6 + BT 5.2 | $10 |
| Thread/Matter | $4 |
| PMIC & regulators | $12 |
| USB-C PD | $2.50 |
| Heatsink | $2.50 |
| PCB (6-layer) | $10 |
| Premium enclosure | $13 |
| Glass lens | $5 |
| Articulating mount | $7 |
| Assembly labor | $15 |
| **Total** | **$278** |

**Target:** $175 per unit at 1,000+ volume
**Gap:** Need to optimize ($103 savings needed)

**This is challenging but possible:**
- Volume pricing (10% across board) = $28 saved
- Cheaper storage (256GB instead of 512GB) = $30 saved
- Alternative SoC (i.MX 8M Plus) = $15-20 saved
- Simplify enclosure = $5 saved
- Negotiate assembly = $5 saved
- Optimized PCB design = $3 saved
- Total savings: ~$86-91

**Revised realistic cost:** $187-192 at 1,000+ units (still above target)

**Options:**
1. Accept higher COGS ($190) and adjust retail price to $349
2. Further cost optimization in design phase
3. Start with Pro model only (no Core initially)

---

## Extended Battery Pack (Accessory)

### Specifications

| Specification | Value |
|---------------|-------|
| **Capacity** | 12,000mAh |
| **Type** | Li-ion rechargeable |
| **Connector** | Magnetic (pogo pins) |
| **Compatibility** | Both Core and Pro models |
| **Additional Runtime** | +24hrs (Core), +15hrs (Pro) |
| **Dimensions** | ~100mm x 80mm x 20mm |
| **Weight** | ~250g |
| **Pass-through Charging** | Yes (charge pack + device simultaneously) |
| **Cost** | $28-35 |
| **Retail** | $79 |

**Components:**
- 12,000mAh battery cells: $18-22
- Protection circuit: $3-4
- Magnetic connector: $2-3
- Housing: $3-5
- Circuitry & assembly: $2-3

---

## Development Boards for Testing

### Phase 2: Production Hardware Testing

**Core Model Testing:**

| Board | SoC | Cost | Purpose |
|-------|-----|------|---------|
| **Radxa Zero 3** | RK3566 (close to RV1126) | $60-80 | Test 720p encoding, basic AI |

**Pro Model Testing:**

| Board | SoC | Cost | Purpose |
|-------|-----|------|---------|
| **Orange Pi 5 Plus** | RK3588 | $150-180 | Test 4K encoding, full AI |
| **Rock 5 Model B** | RK3588 | $130-160 | Alternative option |

**Total Dev Board Investment:** $210-260

---

## Server Hardware (Self-Hosted Infrastructure)

### Development/Small Scale (up to 500 users)

**Option: Used Dell PowerEdge R730**

| Specification | Value |
|---------------|-------|
| **CPU** | 2× Xeon E5-2680 v4 (28 cores total) |
| **RAM** | 128GB DDR4 ECC |
| **Storage** | 2× 500GB SSD (RAID 1, OS), 4× 4TB HDD (RAID 10, data) |
| **Network** | Dual 10GbE |
| **Power** | Redundant PSU |
| **Cost** | $1,000-1,200 (used on eBay) |
| **Capacity** | 500-1,000 users |

### Medium Scale (1,000-5,000 users)

**2× Dell PowerEdge R730**

- Primary + Replica for redundancy
- Total cost: ~$2,000
- Capacity: 1,000-2,000 users

### Large Scale (5,000-10,000 users)

**3-Server Cluster:**
- 2× Compute servers (R740, $2,500 each)
- 1× Storage server (R730XD, 24-bay, $2,000)
- Total: ~$7,000
- Capacity: 5,000-10,000 users

---

## Manufacturing Equipment (Future)

### PCB Assembly

**Initial:** Contract manufacturer (recommended)
- No equipment investment
- Pay per-unit assembly cost
- Faster to market

**Future (if scaling to 10,000+ units/year):**
- Pick-and-place machine: $30,000-100,000
- Reflow oven: $5,000-15,000
- Only viable at very high volume

### Testing Equipment

| Equipment | Purpose | Cost |
|-----------|---------|------|
| Oscilloscope | Signal debugging | $500-2,000 |
| Logic analyzer | Digital signal analysis | $300-1,000 |
| Power supply | Bench testing | $200-500 |
| Multimeter | Basic testing | $50-200 |
| **Total** | | ~$1,050-3,700 |

**Needed:** Phase 3 (production hardware testing) onwards

---

## Summary: Hardware Investment Timeline

| Phase | Hardware Needed | Cost |
|-------|----------------|------|
| **Phase 1-2** | Prototype (Pi 4 + sensors) | $215 |
| **Phase 3-5** | Dev boards for production testing | $260 |
| **Phase 6** | Server for beta testing | $1,200 |
| **Phase 7** | Testing equipment | $1,000 |
| **Phase 8** | 5-10 beta units (assembled) | $500-1,000 |
| **Phase 9** | PCB design, molds, certifications | $60,000-120,000 |
| **Phase 9** | First production run (1,000 units) | $85,500 |
| **Total** | | **$148,675-209,175** |

**Phased Approach:**
- Phases 1-5: $1,675 (low risk, validate concept)
- Phases 6-8: $2,700 (medium risk, beta testing)
- Phase 9: $145,500-204,500 (high risk, requires capital)

---

**Last Updated:** 2025-11-17
**Document Version:** 1.0
**Status:** Approved
