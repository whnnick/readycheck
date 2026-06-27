import {mkdirSync, writeFileSync} from 'node:fs';
import {dirname, join} from 'node:path';
import {fileURLToPath} from 'node:url';

const sampleRate = 44100;
const durationSeconds = 30;
const bpm = 112;
const totalSamples = sampleRate * durationSeconds;
const channels = 2;
const bytesPerSample = 2;

const here = dirname(fileURLToPath(import.meta.url));
const outPath = join(here, '..', 'public', 'audio', 'readycheck-tech-pulse.wav');

const clamp = (value, min, max) => Math.min(max, Math.max(min, value));
const secondsPerBeat = 60 / bpm;
const tau = Math.PI * 2;

const envelope = (time, start, attack, decay, curve = 2.2) => {
  const age = time - start;
  if (age < 0 || age > decay) return 0;
  if (age < attack) return age / attack;
  return Math.pow(1 - (age - attack) / (decay - attack), curve);
};

const sine = (freq, time, phase = 0) => Math.sin(tau * freq * time + phase);
const triangle = (phase) => 1 - 4 * Math.abs(Math.round(phase - 0.25) - (phase - 0.25));
const softClip = (value) => Math.tanh(value * 1.25) / Math.tanh(1.25);

const bassNotes = [41.2, 41.2, 49.0, 55.0, 61.7, 55.0, 49.0, 41.2];
const chordPads = [
  [164.81, 196.0, 246.94, 329.63],
  [146.83, 196.0, 220.0, 293.66],
  [130.81, 164.81, 196.0, 261.63],
  [146.83, 184.99, 220.0, 293.66],
];
const glassNotes = [659.25, 739.99, 554.37, 493.88, 659.25, 830.61, 739.99, 554.37];

const samples = new Float32Array(totalSamples * channels);
const kickStarts = [];
const rimStarts = [];
const hatStarts = [];
const pluckStarts = [];

for (let beat = 0; beat < durationSeconds / secondsPerBeat + 4; beat += 1) {
  kickStarts.push(beat * secondsPerBeat);
  if (beat % 2 === 1) rimStarts.push(beat * secondsPerBeat);
  if (beat % 1 === 0) hatStarts.push(beat * secondsPerBeat + secondsPerBeat * 0.52);
  if (beat % 2 === 0) pluckStarts.push(beat * secondsPerBeat + secondsPerBeat * 0.24);
}

for (let i = 0; i < totalSamples; i += 1) {
  const time = i / sampleRate;
  const beat = time / secondsPerBeat;
  const bar = Math.floor(beat / 4);
  const intro = clamp(time / 2.2, 0, 1);
  const outro = clamp((durationSeconds - time) / 2.4, 0, 1);
  const master = intro * outro;

  const bassFreq = bassNotes[Math.floor(beat * 2) % bassNotes.length];
  const bassGate = Math.pow(1 - ((beat * 2) % 1), 3.1);
  const bass =
    (sine(bassFreq, time) * 0.7 + sine(bassFreq * 2, time, 0.4) * 0.12) *
    bassGate *
    0.42;

  const padChord = chordPads[bar % chordPads.length];
  let pad = 0;
  for (let idx = 0; idx < padChord.length; idx += 1) {
    const freq = padChord[idx];
    pad +=
      (sine(freq, time, idx * 0.7) * 0.045 +
        sine(freq * 0.5, time, idx * 0.4) * 0.035) *
      (0.62 + 0.38 * sine(0.07 + idx * 0.01, time));
  }

  let kick = 0;
  for (const start of kickStarts) {
    const env = envelope(time, start, 0.004, 0.24, 2.8);
    if (env > 0) {
      const age = time - start;
      const pitch = 42 + 82 * Math.pow(1 - age / 0.24, 2.2);
      kick += sine(pitch, age) * env * 0.72;
    }
  }

  let rim = 0;
  for (const start of rimStarts) {
    const env = envelope(time, start, 0.002, 0.11, 2.4);
    if (env > 0) {
      rim += (sine(1190, time) * 0.45 + sine(2420, time) * 0.18) * env * 0.12;
    }
  }

  let hat = 0;
  for (const start of hatStarts) {
    const env = envelope(time, start, 0.001, 0.045, 2.0);
    if (env > 0) {
      hat += (sine(6200, time) * 0.4 + sine(7600, time) * 0.2) * env * 0.035;
    }
  }

  let glass = 0;
  for (const start of pluckStarts) {
    const env = envelope(time, start, 0.006, 0.32, 2.7);
    if (env > 0) {
      const note = glassNotes[Math.floor(start / (secondsPerBeat * 2)) % glassNotes.length];
      glass +=
        (triangle(note * time) * 0.05 +
          sine(note * 2, time, 0.2) * 0.028 +
          sine(note * 3, time, 0.5) * 0.012) *
        env;
    }
  }

  const sidechain = 0.78 + 0.22 * Math.pow(Math.sin(Math.PI * (beat % 1)), 2);
  const lowPulse = sine(30.87, time) * Math.pow(Math.max(0, Math.sin(Math.PI * (beat % 1))), 3.2) * 0.05;
  const shimmer = sine(980, time, 1.2) * sine(0.13, time) * 0.012;
  const mix = softClip((bass + kick + rim + hat + glass + lowPulse + pad * sidechain + shimmer) * master);
  const pan = Math.sin(time * 0.41) * 0.14;

  samples[i * 2] = clamp(mix * (1 - pan), -0.95, 0.95);
  samples[i * 2 + 1] = clamp(mix * (1 + pan), -0.95, 0.95);
}

const dataSize = samples.length * bytesPerSample;
const buffer = Buffer.alloc(44 + dataSize);
buffer.write('RIFF', 0);
buffer.writeUInt32LE(36 + dataSize, 4);
buffer.write('WAVE', 8);
buffer.write('fmt ', 12);
buffer.writeUInt32LE(16, 16);
buffer.writeUInt16LE(1, 20);
buffer.writeUInt16LE(channels, 22);
buffer.writeUInt32LE(sampleRate, 24);
buffer.writeUInt32LE(sampleRate * channels * bytesPerSample, 28);
buffer.writeUInt16LE(channels * bytesPerSample, 32);
buffer.writeUInt16LE(bytesPerSample * 8, 34);
buffer.write('data', 36);
buffer.writeUInt32LE(dataSize, 40);

for (let i = 0; i < samples.length; i += 1) {
  buffer.writeInt16LE(Math.round(samples[i] * 32767), 44 + i * bytesPerSample);
}

mkdirSync(dirname(outPath), {recursive: true});
writeFileSync(outPath, buffer);
console.log(`Generated ${outPath}`);
