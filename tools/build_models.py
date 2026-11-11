import argparse
import math
import os
import numpy as np
import trimesh
from trimesh.visual.material import PBRMaterial

parser = argparse.ArgumentParser()
parser.add_argument("--output", default="assets/models")
OUT = parser.parse_args().output
PIECES = os.path.join(OUT, "pieces")
os.makedirs(PIECES, exist_ok=True)
N = 40

def mat(name, color, metal=0.92, rough=0.2):
    return PBRMaterial(name=name, baseColorFactor=color, metallicFactor=metal, roughnessFactor=rough)

SILVER = mat("Polished Platinum", [205, 216, 228, 255], .97, .16)
DARK = mat("Black Chrome", [38, 47, 61, 255], .96, .18)
GOLD = mat("Champagne Gold", [212, 169, 83, 255], .94, .18)
BLACK = mat("Obsidian Enamel", [16, 19, 25, 255], .72, .23)

def lathe(profile, material, segments=N):
    vertices, faces = [], []
    for radius, y in profile:
        for i in range(segments):
            a = math.tau * i / segments
            vertices.append([radius * math.cos(a), y, radius * math.sin(a)])
    for j in range(len(profile)-1):
        for i in range(segments):
            a = j*segments+i
            b = j*segments+(i+1)%segments
            c = (j+1)*segments+(i+1)%segments
            d = (j+1)*segments+i
            faces.extend([[a,b,c],[a,c,d]])
    mesh = trimesh.Trimesh(vertices=vertices, faces=faces, process=True)
    mesh.visual = trimesh.visual.TextureVisuals(material=material)
    return mesh

def cyl(r, h, y, material, top=None):
    t = r if top is None else top
    return lathe([(0,y-h/2),(r*.97,y-h/2),(r,y-h*.43),(t,y+h*.43),(t*.97,y+h/2),(0,y+h/2)], material, 32)

def sphere(pos, scale, material, sub=2):
    m = trimesh.creation.icosphere(subdivisions=sub)
    m.apply_scale(scale); m.apply_translation(pos)
    m.visual = trimesh.visual.TextureVisuals(material=material)
    return m

def box(pos, size, material):
    m = trimesh.creation.box(extents=size); m.apply_translation(pos)
    m.visual = trimesh.visual.TextureVisuals(material=material)
    return m

def torus(pos, major, minor, material):
    m = trimesh.creation.torus(major_radius=major, minor_radius=minor, major_sections=48, minor_sections=10)
    m.apply_transform(trimesh.transformations.rotation_matrix(-math.pi/2,[1,0,0]))
    m.apply_translation(pos)
    m.visual = trimesh.visual.TextureVisuals(material=material)
    return m

def cone(r,h,y,material):
    return lathe([(0,y-h/2),(r,y-h/2),(r*.78,y),(r*.48,y+h*.28),(0,y+h/2)],material,32)

def base():
    return [
        lathe([(0,0),(.31,0),(.36,.035),(.355,.09),(.33,.13),(.29,.16),(.27,.20),(.22,.23),(0,.23)], BLACK),
        torus([0,.055,0],.345,.018,GOLD), torus([0,.155,0],.298,.014,GOLD)
    ]

def pawn():
    p=base()
    p += [lathe([(0,.22),(.20,.22),(.19,.28),(.145,.34),(.12,.42),(.105,.58),(.125,.68),(.17,.72),(.16,.77),(.11,.80),(0,.80)],SILVER),
          sphere([0,.94,0],[.155,.155,.155],SILVER,3), torus([0,.76,0],.145,.018,GOLD),torus([0,.30,0],.184,.012,GOLD)]
    return p

def rook():
    p=base()
    p += [lathe([(0,.22),(.20,.22),(.19,.30),(.15,.38),(.13,.48),(.145,.57),(.19,.63),(.205,.70),(.205,1.08),(.25,1.14),(.27,1.20),(.26,1.25),(.21,1.28),(0,1.28)],SILVER),
          torus([0,.65,0],.205,.018,GOLD),torus([0,1.12,0],.25,.018,GOLD),cyl(.25,.12,1.34,SILVER)]
    for i in range(8):
        a=math.tau*i/8
        p.append(box([.205*math.cos(a),1.47,.205*math.sin(a)],[.105,.22,.105],SILVER))
    p.append(cyl(.155,.035,1.405,BLACK))
    return p

def bishop():
    p=base()
    p += [lathe([(0,.22),(.20,.22),(.19,.30),(.15,.38),(.12,.55),(.105,.77),(.14,.91),(.19,1.00),(.18,1.07),(.13,1.12),(0,1.12)],SILVER),
          sphere([0,1.19,0],[.18,.18,.18],SILVER,3),cone(.17,.46,1.48,SILVER),
          sphere([0,1.73,0],[.045,.065,.045],GOLD,2),torus([0,.31,0],.185,.014,GOLD),torus([0,1.07,0],.16,.018,GOLD)]
    seam=box([0,1.50,0],[.29,.027,.026],GOLD)
    seam.apply_transform(trimesh.transformations.rotation_matrix(math.radians(-32),[0,0,1],point=[0,1.50,0]))
    p.append(seam)
    return p

def queen():
    p=base()
    p += [lathe([(0,.22),(.20,.22),(.19,.31),(.15,.38),(.13,.52),(.105,.72),(.12,.94),(.17,1.05),(.22,1.10),(.24,1.17),(.22,1.22),(0,1.22)],SILVER),
          torus([0,.34,0],.18,.016,GOLD),torus([0,1.12,0],.225,.018,GOLD),
          lathe([(0,1.18),(.22,1.18),(.25,1.24),(.22,1.29),(.18,1.31),(0,1.31)],GOLD)]
    for i in range(8):
        a=math.tau*i/8; x,z=.20*math.cos(a),.20*math.sin(a)
        p += [cone(.055,.25,1.42,GOLD),sphere([x,1.56,z],[.045,.045,.045],GOLD,2)]
        p[-2].apply_translation([x,0,z])
    p.append(sphere([0,1.40,0],[.105,.105,.105],SILVER,3))
    return p

def king():
    p=base()
    p += [lathe([(0,.22),(.20,.22),(.19,.31),(.15,.39),(.13,.57),(.11,.82),(.13,1.02),(.18,1.14),(.22,1.21),(.24,1.28),(.21,1.33),(0,1.33)],SILVER),
          torus([0,.34,0],.18,.016,GOLD),torus([0,1.23,0],.225,.018,GOLD),
          sphere([0,1.39,0],[.17,.17,.17],SILVER,3),cyl(.065,.38,1.68,GOLD),
          box([0,1.76,0],[.34,.075,.075],GOLD),sphere([0,1.76,.06],[.052,.052,.052],SILVER,2)]
    return p

def knight():
    p=base()
    p += [lathe([(0,.22),(.20,.22),(.19,.31),(.15,.39),(.13,.50),(.16,.58),(.20,.65),(.16,.70),(0,.70)],SILVER),
          sphere([0,.88,.015],[.17,.30,.18],SILVER,3),sphere([0,1.06,.13],[.15,.27,.16],SILVER,3),
          sphere([0,1.18,.27],[.13,.12,.25],SILVER,3),sphere([0,1.10,.43],[.105,.085,.17],SILVER,3),
          sphere([0,1.00,.52],[.11,.07,.11],SILVER,2)]
    for side in [-1,1]:
        ear=cone(.065,.24,1.42,SILVER)
        ear.apply_transform(trimesh.transformations.rotation_matrix(math.radians(side*14),[0,0,1]))
        ear.apply_translation([side*.075,0,.04]); p.append(ear)
        p.append(sphere([side*.125,1.19,.32],[.025,.025,.025],BLACK,2))
    for i in range(5):
        z=-.03+i*.095; y=1.18-i*.075
        ridge=box([0,y,z],[.075,.12,.11],GOLD if i==0 else DARK)
        ridge.apply_transform(trimesh.transformations.rotation_matrix(math.radians(-18),[1,0,0],point=[0,y,z]))
        p.append(ridge)
    p.append(torus([0,.31,0],.185,.014,GOLD))
    return p

for name, builder in {"pawn":pawn,"rook":rook,"knight":knight,"bishop":bishop,"queen":queen,"king":king}.items():
    scene=trimesh.Scene(base_frame="ChessVerse3D")
    for i,mesh in enumerate(builder()):
        scene.add_geometry(mesh,node_name=f"{name}_detail_{i:02d}",geom_name=f"{name}_mesh_{i:02d}")
    with open(os.path.join(PIECES,name+".glb"),"wb") as f:
        f.write(scene.export(file_type="glb"))

scene=trimesh.Scene(base_frame="ChessVerse3D")
board_dark=mat("Obsidian Marble",[22,27,36,255],.38,.24)
board_light=mat("Warm Ivory Marble",[190,174,143,255],.22,.28)
board_gold=mat("Machined Brass Frame",[190,143,65,255],.90,.20)
board_base=mat("Black Lacquer Plinth",[10,13,19,255],.62,.21)
def add(mesh,name): scene.add_geometry(mesh,node_name=name,geom_name=name)
add(box([0,-.13,0],[8.5,.28,8.5],board_base),"board_plinth")
for x in [-4.16,4.16]: add(box([x,.035,0],[.07,.10,8.38],board_gold),f"frame_x_{x}")
for z in [-4.16,4.16]: add(box([0,.035,z],[8.38,.10,.07],board_gold),f"frame_z_{z}")
for z in range(8):
    for x in range(8):
        add(box([x-3.5,.025,z-3.5],[.995,.09,.995],board_light if (x+z)%2==0 else board_dark),f"square_{x}_{z}")
with open(os.path.join(OUT,"board.glb"),"wb") as f:
    f.write(scene.export(file_type="glb"))
print("Generated 6 metallic chess pieces and 1 marble chessboard.")
