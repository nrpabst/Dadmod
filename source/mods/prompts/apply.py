"""Button prompts (mods/prompts): remember how each helper bar was made, so it can be made again when the player
switches between keyboard and controller (menuui/menuitem.q dadmod_helper_seen / dadmod_helper_refresh).

    python -I mods/prompts/apply.py <server build mod tree>     (build/obsspawn_test_make.sh, server build)

Server build: inserts one call at the top of the stock create_helper_text (copying engine/menu/helper_text.q from
decompiled/thugpro_qb first when the tree doesn't carry it). The client build wraps it instead
(client/wrap.txt + client/qb/dadmod/prompts.q).
"""
import os, re, shutil, sys

WORK = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
KALI = os.path.join(WORK, 'decompiled', 'thugpro_qb', 'qb')
REL = os.path.join('engine', 'menu', 'helper_text.q')
CALL = '    dadmod_helper_seen <...>'
TAIL = '    dadmod_move_hint anchor_id = <anchor_id>'


def main(tree):
    dst = os.path.join(tree, 'qb', REL)
    if not os.path.isfile(dst):
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copyfile(os.path.join(KALI, REL), dst)
    text = open(dst, encoding='latin1', newline='').read()
    nl = '\r\n' if '\r\n' in text else '\n'
    if CALL not in text:
        # the header of create_helper_text is "script create_helper_text {" ... "    }" (its default params)
        m = re.search(r'^script create_helper_text \{\r?\n(?:.*\r?\n)*?    \}\r?\n', text, re.M)
        if not m:
            sys.exit('QB BUILD FAILED: prompts: create_helper_text header not found')
        text = text[:m.end()] + CALL + nl + text[m.end():]
        print('prompts: create_helper_text remembers its bar')
    if TAIL not in text:
        # Move hint (F9 = Move etc.) goes on the end of the bar once it is built
        m = re.search(r'^script create_helper_text \{\r?\n(?:.*\r?\n)*?endscript', text, re.M)
        if not m:
            sys.exit('QB BUILD FAILED: prompts: create_helper_text end not found')
        end = m.end() - len('endscript')
        text = text[:end] + TAIL + nl + text[end:]
        print('prompts: create_helper_text adds the Move hint')
    open(dst, 'w', encoding='latin1', newline='').write(text)


if __name__ == '__main__':
    main(sys.argv[1])
