import os
import sys
from pathlib import Path
import math

class Solution:
    def __init__(self, pi=None, z=None, time=-1.0, profit=-1.0):
        self.pi = pi
        self.z = z
        self.time = time
        self.profit = profit
        self.singleObjective = -1.0
        self.objectives = None

    def get_relation(self, other):
        val = 0
        for a, b in zip(self.objectives, other.objectives):
            if a < b:
                if val == -1:
                    return 0
                val = 1
            elif a > b:
                if val == 1:
                    return 0
                val = -1
        return val

    def equals_in_design_space(self, other):
        return self.pi == other.pi and self.z == other.z

class TravelingThiefProblem:

    def __init__(self):
        self.name = "unknown"
        self.numOfCities = -1
        self.numOfItems = -1
        self.minSpeed = -1
        self.maxSpeed = -1
        self.maxWeight = -1
        self.R = float("inf")
        self.coordinates = None
        self.cityOfItem = None
        self.weight = None
        self.profit = None
        self.itemsAtCity = None

    def initialize(self):
        if (self.numOfCities == -1 or self.numOfItems == -1 or
            self.minSpeed == -1 or self.maxSpeed == -1 or
            self.maxWeight == -1 or self.R == float("inf")):
            raise RuntimeError("Error while loading problem. Missing fields.")

        self.itemsAtCity = [[] for _ in range(self.numOfCities)]
        for i, city in enumerate(self.cityOfItem):
            self.itemsAtCity[city].append(i)

    def evaluate(self, pi, z, copy=False):
        if len(pi) != self.numOfCities or len(z) != self.numOfItems:
            raise RuntimeError("Wrong input for traveling thief evaluation.")

        if pi[0] != 0:
            raise RuntimeError("Thief must start at city 0.")

        time = 0.0
        profit = 0.0
        weight = 0.0

        for i in range(self.numOfCities):
            city = pi[i]

            # Item picking
            for item in self.itemsAtCity[city]:
                if z[item]:
                    weight += self.weight[item]
                    profit += self.profit[item]

            if weight > self.maxWeight:
                time = float("inf")
                profit = -float("inf")
                break

            speed = self.maxSpeed - (weight / self.maxWeight) * (self.maxSpeed - self.minSpeed)
            nxt = pi[(i + 1) % self.numOfCities]
            dist = math.ceil(self.euclidean_distance(city, nxt))
            time += dist / speed

        s = Solution(pi[:] if copy else pi, z[:] if copy else z, time, profit)
        s.singleObjective = profit - self.R * time
        s.objectives = [time, -profit]
        return s

    def euclidean_distance(self, a, b):
        dx = self.coordinates[a][0] - self.coordinates[b][0]
        dy = self.coordinates[a][1] - self.coordinates[b][1]
        return math.sqrt(dx * dx + dy * dy)

    def verify(self, s):
        correct = self.evaluate(s.pi, s.z)
        if s.time != correct.time or s.profit != correct.profit:
            raise RuntimeError("Pi and Z do not match the objectives.")
        
def read_problem(file_obj):
    p = TravelingThiefProblem()

    lines = (line.strip() for line in file_obj)
    for line in lines:

        if "DIMENSION" in line:
            p.numOfCities = int(line.split(":")[1])
            p.coordinates = [[0.0, 0.0] for _ in range(p.numOfCities)]

        elif "NUMBER OF ITEMS" in line:
            p.numOfItems = int(line.split(":")[1])
            p.cityOfItem = [0] * p.numOfItems
            p.weight = [0.0] * p.numOfItems
            p.profit = [0.0] * p.numOfItems

        elif "RENTING RATIO" in line:
            p.R = float(line.split(":")[1])

        elif "CAPACITY OF KNAPSACK" in line:
            p.maxWeight = int(line.split(":")[1])

        elif "MIN SPEED" in line:
            p.minSpeed = float(line.split(":")[1])

        elif "MAX SPEED" in line:
            p.maxSpeed = float(line.split(":")[1])

        elif "EDGE_WEIGHT_TYPE" in line:
            typ = line.split(":")[1].strip()
            if typ != "CEIL_2D":
                raise RuntimeError("Only CEIL_2D is supported.")

        elif "NODE_COORD_SECTION" in line:
            for i in range(p.numOfCities):
                parts = next(lines).split()
                p.coordinates[i][0] = float(parts[1])
                p.coordinates[i][1] = float(parts[2])

        elif "ITEMS SECTION" in line:
            for i in range(p.numOfItems):
                parts = next(lines).split()
                p.profit[i] = float(parts[1])
                p.weight[i] = float(parts[2])
                p.cityOfItem[i] = int(parts[3]) - 1

    p.initialize()
    return p

class Competition:
    TEAM_NAME = "5"

    INSTANCES = [
        "a280-n279",
        "a280-n1395",
        "a280-n2790",
        "fnl4461-n4460",
        "fnl4461-n22300",
        "fnl4461-n44600",
        "pla33810-n33809",
        "pla33810-n169045",
        "pla33810-n338090",
    ]

    @staticmethod
    def number_of_solutions(problem):
        name = problem.name
        if "a280" in name:
            return 100
        if "fnl4461" in name:
            return 50
        if "pla33810" in name:
            return 20
        return 2**31 - 1

def verify():
    TEAM = "5"

    instances = [
        "a280_n279", "a280_n1395", "a280_n2790",
        "fnl4461_n4460", "fnl4461_n22300", "fnl4461_n44600",
        "pla33810_n33809", "pla33810_n169045", "pla33810_n338090"
    ]

    for instance in instances:

        fname = f"gecco19-thief/src/main/resources/{instance.replace('_', '-')}.txt"
        if not os.path.exists(fname):
            print(f"ERROR: Problem file not found: {fname}")
            sys.exit(1)

        # Read problem
        with open(fname, "r") as f:
            problem = read_problem(f)
        problem.name = instance

        inst_fixed = instance.replace("_", "-")

        x_path = Path("gecco19-thief/submissions") / TEAM / f"{TEAM}_{inst_fixed}.x"
        f_path = Path("gecco19-thief/submissions") / TEAM / f"{TEAM}_{inst_fixed}.f"

        if not f_path.exists():
            print(f"ERROR: Objective file not found: {f_path}")
            sys.exit(1)
        if not x_path.exists():
            print(f"ERROR: Solution file not found: {x_path}")
            sys.exit(1)

        with open(f_path, "r") as obj_file:
            objectives = obj_file.read().strip().split("\n")

        counter = 0

        with open(x_path, "r") as br:
            lines = br.readlines()

        i = 0
        while i < len(lines):

            line = lines[i].strip()
            i += 1

            if line == "":
                continue

            # Parse pi
            pi = [int(x.strip()) for x in line.replace(",", " ").split()]
            if pi[0] == 1:
                pi = [x - 1 for x in pi]

            if len(pi) != problem.numOfCities:
                print("ERROR")
                print(f"Solution {counter}")
                print(f"Wrong tour length {len(pi)} != {problem.numOfCities}")
                print("Submission can not be accepted.")
                sys.exit(1)

            visited = [False] * problem.numOfCities
            for c in pi:
                visited[c] = True

            if not all(visited):
                print("ERROR")
                print(f"Solution {counter}")
                print("Not all cities are visited.")
                print("Submission can not be accepted.")
                sys.exit(1)

            # Parse z
            if i >= len(lines):
                print("ERROR: Missing packing plan line")
                sys.exit(1)

            line = lines[i].strip()
            i += 1

            z = [(b.strip() == "1") for b in line.replace(",", " ").split()]

            # Evaluate
            solution = problem.evaluate(pi, z)

            # Compare with objective file
            vals = objectives[counter].split()
            time_reported = float(vals[0])
            profit_reported = float(vals[1])

            precision = 1e-4
            if (abs(time_reported - solution.time) > precision or
                abs(profit_reported - solution.profit) > precision):
                print("ERROR")
                print(f"Solution {counter}")
                print(f"Reported time is {time_reported}. Evaluated {solution.time}.")
                print(f"Reported profit is {profit_reported}. Evaluated {solution.profit}.")
                print("Submissions file do not match!")
                sys.exit(1)

            # Skip empty line
            if i < len(lines) and lines[i].strip() == "":
                i += 1

            counter += 1

        number_of_solutions = Competition.number_of_solutions(problem)
        if counter > number_of_solutions:
            print(
                f"WARNING: Finally the competition allows only {number_of_solutions} solutions "
                f"to be submitted. Your algorithm found {counter} solutions."
            )

        print(f"{instance}: Submission is correct ({counter} / {number_of_solutions}).")

if __name__ == "__main__":
    verify()