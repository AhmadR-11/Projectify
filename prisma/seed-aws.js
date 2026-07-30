const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting AWS RDS Seed Script...');

  // 1. Create Campus
  let campusCFD = await prisma.campus.findFirst({
    where: { name: 'CFD' },
  });

  if (!campusCFD) {
    campusCFD = await prisma.campus.create({
      data: {
        name: 'CFD',
        location: 'Chiniot-Faisalabad Campus',
      },
    });
    console.log('✅ Created CFD Campus:', campusCFD);
  } else {
    console.log('ℹ️ CFD Campus already exists:', campusCFD);
  }

  // Common password hash for test accounts
  const passwordHash = await bcrypt.hash('Password123!', 10);

  // 2. Create Admin User
  const adminEmail = 'admin@projectify.app';
  let adminUser = await prisma.user.findUnique({
    where: { email: adminEmail },
  });

  if (!adminUser) {
    adminUser = await prisma.user.create({
      data: {
        name: 'System Admin',
        email: adminEmail,
        passwordHash: passwordHash,
        role: 'admin',
        admin: { create: {} },
      },
    });
    console.log('✅ Created Admin user (email: admin@projectify.app, pass: Password123!)');
  }

  // 3. Create Coordinator User
  const coordEmail = 'coordinator@projectify.app';
  let coordUser = await prisma.user.findUnique({
    where: { email: coordEmail },
  });

  if (!coordUser) {
    coordUser = await prisma.user.create({
      data: {
        name: 'FYP Coordinator',
        email: coordEmail,
        passwordHash: passwordHash,
        role: 'coordinator',
        coordinator: {
          create: {
            campusId: campusCFD.campusId,
          },
        },
      },
    });
    console.log('✅ Created Coordinator user (email: coordinator@projectify.app, pass: Password123!)');
  }

  // 4. Create Student Users with Roll Numbers
  const studentsToCreate = [
    {
      name: 'Ali Student',
      email: 'student1@projectify.app',
      rollNumber: '21F-9123',
    },
    {
      name: 'Sara Student',
      email: 'student2@projectify.app',
      rollNumber: '21F-9124',
    },
  ];

  for (const s of studentsToCreate) {
    let studentUser = await prisma.user.findUnique({
      where: { email: s.email },
    });

    if (!studentUser) {
      studentUser = await prisma.user.create({
        data: {
          name: s.name,
          email: s.email,
          passwordHash: passwordHash,
          role: 'student',
          student: {
            create: {
              rollNumber: s.rollNumber,
              campusId: campusCFD.campusId,
              batch: '2021',
            },
          },
        },
      });
      console.log(`✅ Created Student (Roll: ${s.rollNumber}, Email: ${s.email}, Pass: Password123!)`);
    }
  }

  console.log('\n🎉 AWS RDS Seeding Completed Successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Error seeding RDS:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
