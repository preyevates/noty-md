// Markdown fidelity through the vendored editor engine.
//
// Every note the user opens is parsed by Lute (Vditor's Markdown engine) into the IR editing
// DOM and serialised back to Markdown on each edit. Whatever that round trip changes is what
// lands on disk. This test pins the round trip for the syntax a Fan Fold library shares with
// Obsidian, so a Vditor/Lute upgrade that starts rewriting it fails here instead of silently
// rewriting people's notes.
//
// Two canonicalisations are KNOWN and cosmetic; they are asserted exactly so that any change
// in the engine's behaviour (better or worse) is noticed:
//   1. Task list items: `- [x] a` becomes `- [X]  a` (upper-case X, two spaces), and
//      `- [ ] b` becomes `- [ ]  b`.
//   2. The blank line directly after a YAML front matter block's closing `---` is removed.
//      The front matter lines themselves survive byte for byte.
//
// This test observes the engine only; it does not change editor behaviour.
const assert = require('node:assert/strict');
const path = require('node:path');

global.window = global.self = global;
require(path.resolve(__dirname, '../../third_party/vditor-3.11.2/dist/js/lute/lute.min.js'));

function engine(sanitize) {
    const lute = Lute.New();
    lute.SetVditorIR(true);
    // editor.js configures Vditor with markdown.sanitize:true; check both the bare engine and
    // the configuration the editor actually runs.
    if (sanitize) lute.SetSanitize(true);
    return text => lute.VditorIRDOM2Md(lute.Md2VditorIRDOM(text));
}

for (const sanitize of [false, true]) {
    const roundTrip = engine(sanitize);
    const label = sanitize ? 'sanitize' : 'bare';

    // Front matter: the block is preserved verbatim.
    const frontMatter = '---\ntitle: Weekly review\ntags: [work, "q3"]\naliases:\n  - review\ncreated: 2026-09-01T10:00:00\n---\n';
    const withFrontMatter = frontMatter + '\n# Heading\n\nBody text.\n';
    const out = roundTrip(withFrontMatter);
    assert.ok(out.startsWith(frontMatter), `${label}: front matter lines must survive verbatim, got ${JSON.stringify(out)}`);
    // Known canonicalisation 2: the blank line after the closing --- is dropped.
    assert.equal(out, frontMatter + '# Heading\n\nBody text.\n', `${label}: front matter canonical form changed`);
    // A front matter block already in canonical form is stable.
    assert.equal(roundTrip(out), out, `${label}: canonical front matter note must be stable`);

    // The editor never ADDS front matter to a plain note.
    for (const plain of ['plain\n', '# Title\n\nSome text.\n', 'Line one\n\n---\n\nAfter a rule\n']) {
        const result = roundTrip(plain);
        assert.ok(!result.startsWith('---'), `${label}: front matter added to ${JSON.stringify(plain)}: ${JSON.stringify(result)}`);
        assert.equal(result, plain, `${label}: plain note changed`);
    }

    // Obsidian syntax survives identically.
    const obsidian = [
        '[[wikilink]]\n',
        '[[a|alias]]\n',
        '![[embed.png]]\n',
        '> [!note] Title\n> Callout body\n',
        '#tag\n',
        'text with #tag inside\n',
        '==highlight==\n',
        '%%comment%%\n',
        'Mixed [[Note]] and ==mark== with #tag and %%hidden%% plus ![[pic.png]]\n',
    ];
    for (const text of obsidian)
        assert.equal(roundTrip(text), text, `${label}: Obsidian syntax changed: ${JSON.stringify(text)}`);

    // Known canonicalisation 1: task items.
    assert.equal(roundTrip('- [x] a\n- [ ] b\n'), '- [X]  a\n- [ ]  b\n', `${label}: task item canonical form changed`);
}

console.log('markdown fidelity: ok');
