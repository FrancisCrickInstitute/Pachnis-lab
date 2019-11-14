# -*- coding: utf-8 -*-
"""
Created on Fri May 24 16:34:49 2019
% * Copyright (C) 2019 Todd Fallesen <todd.fallesen at crick dot ac dot uk>
% *
% * This program is free software: you can redistribute it and/or modify
% * it under the terms of the GNU General Public License as published by
% * the Free Software Foundation, either version 3 of the License, or
% * (at your option) any later version.
% *
% * This program is distributed in the hope that it will be useful,
% * but WITHOUT ANY WARRANTY; without even the implied warranty of
% * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% * GNU General Public License for more details.
% *
% * You should have received a copy of the GNU General Public License
% * along with this program.  If not, see <http://www.gnu.org/licenses/>.
@author: FallesT
"""

import shutil
import os

sourcedir = "C:\\Users\\fallest\\Documents\\Projects\\Alvaro Castano RNAscope\\Project 2\\Test Images\\Image_1_split"  #change this directory to the location where your images are located
prefix = "R327 #1 CD 40x 002 (rep)_A01_G009_0001.oir - Z="
extension = "tif"

files = [(f, f[f.rfind("."):], f[:f.rfind(".")].replace(prefix, "")) for f in os.listdir(sourcedir) if f.endswith(extension)]
maxlen = len(max([f[2] for f in files], key = len))

for item in files:
    zeros = maxlen - len(item[2])
    shutil.move(sourcedir+"/"+item[0], sourcedir+"/"+prefix+str(zeros*"0"+item[2])+item[1])
